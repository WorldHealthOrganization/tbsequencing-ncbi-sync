import sys
from typing import Iterable

from src.common.logs import create_logger
from src.db.database import Connection, execute_many_with_return
from src.sync_samples.models import Drug, Medium, NormalizationData, PDSTMethod, ResistanceRecord, Sample, Taxon

log = create_logger(__name__)


def update_samples(db: Connection, items: list[Sample]):
    curr = db.cursor()
    curr.executemany(
        """
        UPDATE "submission_sample" SET
            biosample_id=%s,
            ncbi_taxon_id=%s,
            submission_date=%s,
            sampling_date=%s,
            latitude=%s,
            longitude=%s,
            country_id=%s,
            additional_geographical_information=%s,
            isolation_source=%s
        WHERE id = %s
    """,
        [
            (
                item.biosample_id,
                item.ncbi_taxon_id,
                item.submission_date,
                item.sampling_date,
                item.latitude,
                item.longitude,
                item.country_id,
                item.geo_loc_name,
                item.isolation_source,
                item.db_sample_id,
            )
            for item in items
        ],
    )


def get_samples_with_missing_ncbi_data_count(db: Connection) -> int:
    curr = db.cursor()
    curr.execute(
        """SELECT COUNT(s.id) from submission_samplealias s
            join submission_sample t on t.id = s.sample_id
            where t.origin='NCBI'
            and t.biosample_id is NULL
            and s.origin = 'BioSample'"""
    )
    samples_count = curr.fetchone()
    assert samples_count
    return samples_count[0]


def get_samples_with_missing_ncbi_data(db: Connection, per_page: int, last_id: int) -> list[tuple[str, int, int, int]]:
    curr = db.cursor()
    curr.execute(
        """SELECT s.name, t.id, s.package_id, s.id from submission_samplealias s
            join submission_sample t on t.id = s.sample_id
            where
                t.id > %s
                and t.origin='NCBI'
                and t.biosample_id is NULL
                and s.origin = 'BioSample'
                order by t.id
                limit %s""",
        (last_id, per_page),
    )
    samples = curr.fetchall()
    return samples  # type: ignore


def get_taxon_ids(db: Connection, ids: Iterable[int]) -> list[Taxon]:
    curr = db.cursor()
    curr.execute(
        """
        SELECT taxon_id, ncbi_taxon_id FROM biosql.taxon WHERE ncbi_taxon_id = ANY(%s);
    """,
        (list(ids),),
    )
    return [Taxon(id=row[0], ncbi_id=row[1]) for row in curr.fetchmany(sys.maxsize)]


def get_mediums(curr) -> list[Medium]:
    curr.execute("SELECT medium_id, medium_name FROM public.genphen_growthmedium;")
    return [Medium(id=int(row[0]), name=row[1]) for row in curr.fetchmany(sys.maxsize)]


def get_pdst_methods(curr) -> list[PDSTMethod]:
    curr.execute("SELECT method_id, method_name FROM public.genphen_pdsassessmentmethod;")
    return [PDSTMethod(id=int(row[0]), name=row[1]) for row in curr.fetchmany(sys.maxsize)]


def get_drugs(curr) -> list[Drug]:
    drugs: dict[int, Drug] = {}

    curr.execute("SELECT drug_id, drug_name FROM public.genphen_drug;")
    for row in curr.fetchall():
        drug = drugs.setdefault(int(row[0]), Drug(id=int(row[0]), names=[]))
        drug.names.append(row[1])

    curr.execute("SELECT drug_id, drug_name_synonym FROM public.genphen_drugsynonym;")
    for row in curr.fetchall():
        drug = drugs.setdefault(int(row[0]), Drug(id=int(row[0]), names=[]))
        drug.names.append(row[1])
    return list(drugs.values())


def get_normalisation_data(db: Connection) -> NormalizationData:
    cur = db.cursor()
    data = NormalizationData(drugs=get_drugs(cur), mediums=get_mediums(cur), methods=get_pdst_methods(cur))
    log.info(
        "Normalization data collected: %s drugs, %s mediums, %s methods",
        len(data.drugs),
        len(data.mediums),
        len(data.methods),
    )
    return data


def insert_pds_tests(db: Connection, items: list[tuple[Sample, ResistanceRecord]]):
    results = execute_many_with_return(
        db.cursor(),
        """
        INSERT INTO submission_pdstest(
            "concentration", "test_result", "staging", "drug_id", "medium_id",
            "method_id", "package_id", "sample_id", "sample_alias_id")
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING id;
    """,
        [
            (
                record.concentration,
                record.result,
                False,
                record.drug.id if record.drug else None,
                record.medium.id if record.medium else None,
                record.method.id if record.method else None,
                sample.package_id,
                sample.db_sample_id,
                sample.alias_id,
            )
            for sample, record in items
        ],
    )

    assert len(results) == len(items)

    for i, row in enumerate(results):
        items[i][1].db_id = row[0]


def get_samples_by_biosample_ids(db: Connection, ids: Iterable[int]) -> dict[int, int]:
    curr = db.cursor()
    curr.execute(
        """
        SELECT id, biosample_id FROM submission_sample WHERE biosample_id = ANY(%s);
        """,
        (list(ids),),
    )
    return {row[1]: row[0] for row in curr.fetchmany(sys.maxsize)}
