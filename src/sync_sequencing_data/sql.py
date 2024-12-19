import sys
from datetime import datetime
from typing import Iterable

from src.common.logs import create_logger
from src.db.database import Connection, execute_many_with_return
from src.sync_sequencing_data.models import NewSampleAlias, SampleAliasMatched, SRARunResultFile

log = create_logger(__name__)


def create_ncbi_package(db: Connection, name: str) -> int:
    curr = db.cursor()

    curr.execute(
        """
        INSERT INTO public.submission_package(
            "origin", "bioproject_id", "name", "submitted_on", "state_changed_on",
            "state", "matching_state", "rejection_reason"
        )
        VALUES ('NCBI', -1, %s, NOW(), NOW(), 'PENDING', 'MATCHED', '')
        RETURNING id;
    """, (name,),
    )

    result = curr.fetchone()
    assert result

    new_ncbi_temporary_package_id = result[0]
    return new_ncbi_temporary_package_id

def get_or_create_temporary_ncbi_package(db: Connection, name: str = '[SYSTEM] NCBI Sync temporary project') -> int:
    curr = db.cursor()

    curr.execute("SELECT id FROM public.submission_package WHERE origin='NCBI' AND bioproject_id = -1;")
    existing_ncbi_temporary_package = curr.fetchone()
    if existing_ncbi_temporary_package:
        return existing_ncbi_temporary_package[0]

    new_ncbi_temporary_package_id = create_ncbi_package(db, name)
    log.warning("Cannot find the temporary NCBI package, created a new one: %s", new_ncbi_temporary_package_id)

    return new_ncbi_temporary_package_id


def create_dummy_samples(db: Connection, tmp_package_id: int, count: int) -> list[int]:
    curr = db.cursor()

    result = execute_many_with_return(
        curr,
        """
        INSERT INTO "submission_sample"(
            "package_id", "biosample_id", "ncbi_taxon_id", "submission_date", "sampling_date",
            "latitude", "longitude", "country_id", "additional_geographical_information",
            "isolation_source", "bioanalysis_status", "origin")
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING id;
    """,
        [
            (tmp_package_id, None, 83332, None, None, None, None, None, None, None, None, "NCBI")
            for _ in range(count)
        ],
    )

    return [r[0] for r in result]


def get_sequencingdata_by_library_name(db: Connection, srss: Iterable[str]) -> list[str]:
    curr = db.cursor()
    curr.execute(
        """
        SELECT submission_sequencingdata.library_name
        FROM submission_sequencingdata
        WHERE submission_sequencingdata.library_name = ANY(%s);
    """,
        (list(srss),),
    )
    return [row[0] for row in curr.fetchmany(sys.maxsize)]


def get_sequencingdata_by_hashes(db: Connection, hashes: Iterable[str]) -> dict[str, int]:
    curr = db.cursor()
    curr.execute(
        """
        SELECT submission_sequencingdatahash.value, submission_sample.id
        FROM submission_sequencingdatahash
        LEFT JOIN submission_sequencingdata ON submission_sequencingdata.id = submission_sequencingdatahash.sequencing_data_id
        LEFT JOIN submission_sample ON submission_sequencingdata.sample_id = submission_sample.id
        WHERE submission_sequencingdatahash.value = ANY(%s);
    """,
        (list(hashes),),
    )
    return {row[0]: int(row[1]) for row in curr.fetchmany(sys.maxsize)}



def get_samples_by_sample_aliases(db: Connection, sample_aliases: list[str]) -> list[SampleAliasMatched]:
    if not sample_aliases:
        return []

    curr = db.cursor()
    curr.execute(
        """
        SELECT sample_id, name FROM submission_samplealias WHERE name = ANY(%s);
    """,
        (sample_aliases,),
    )
    return [SampleAliasMatched(sample_id=row[0], name=row[1]) for row in curr.fetchmany(sys.maxsize)]


def insert_sample_aliases(db: Connection, sample_aliases: Iterable[NewSampleAlias]) -> list[int]:
    curr = db.cursor()

    result = execute_many_with_return(
        curr,
        """
        INSERT INTO "submission_samplealias"("package_id", "sample_id", "name", "verdicts", "created_at",
        "origin", "origin_label")
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        RETURNING id;
    """,
        [
            (s.tmp_package_id, s.sample_id, s.name, "[]", datetime.now(), s.alias_type, s.alias_label)
            for s in sample_aliases
        ],
    )

    return [r[0] for r in result]


def insert_sequencingdata(db: Connection, items: list[SRARunResultFile]):
    curr = db.cursor()

    results = execute_many_with_return(
        curr,
        """
        INSERT INTO submission_sequencingdata(
            sample_id, created_at, library_name, library_preparation_strategy, dna_source,
            dna_selection, sequencing_platform, sequencing_machine, library_layout, data_location)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING id;
    """,
        [
            (
                item.db_sample_id,
                datetime.now(),
                item.library_name,
                item.strategy,
                item.source,
                item.selection,
                item.platform,
                item.machine,
                item.library_layout,
                "NCBI",
            )
            for item in items
        ],
    )

    assert len(results) == len(items)

    for i, row in enumerate(results):
        items[i].db_id = row[0]

    # save hashes now
    results = execute_many_with_return(
        curr,
        """
        INSERT INTO submission_sequencingdatahash(algorithm, value, sequencing_data_id)
        VALUES (%s, %s, %s)
        RETURNING id;
    """,
        [("MD5", hash, item.db_id) for item in items for hash in item.md5_hashes],
    )

    assert len(results) == len([hash for item in items for hash in item.md5_hashes])
    return results
