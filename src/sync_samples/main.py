import argparse
import math
from dataclasses import replace

from src.common import logs
from src.common.logs import set_global_debug
from src.common.stats import Stats
from src.db.database import Connection
from src.entrez.advanced import EntrezAdvanced
from src.entrez.base import DB, xml_to_string
from src.sync_samples import sql
from src.sync_samples.extract_biosample import extract_biosample
from src.sync_samples.models import Sample
from src.sync_samples.sql import get_normalisation_data
from src.sync_sequencing_data.sql import (
    get_samples_by_sample_aliases,
    insert_sample_aliases,
    get_or_create_temporary_ncbi_package,
)

log = logs.create_logger(__name__)


def populate_taxon_ids(db: Connection, samples: list[Sample]) -> tuple[list[Sample], list[Sample]]:
    all_taxon_ids = set(sample.ncbi_taxon_id for sample in samples)
    taxons_found = {t.ncbi_id: t.id for t in sql.get_taxon_ids(db, all_taxon_ids)}
    new_taxon_ids = set(all_taxon_ids) - set(taxons_found.keys())

    if new_taxon_ids:
        log.warning(
            "Detected %s (out of %s total) new taxons which are not present in DB: %s. These "
            "samples will be skipped right now",
            len(new_taxon_ids),
            len(all_taxon_ids),
            new_taxon_ids,
        )

    samples_without_taxon = []
    valid_samples = []
    for sample in samples:
        if sample.ncbi_taxon_id not in taxons_found:
            samples_without_taxon.append(sample)
            continue
        sample.db_taxon_id = taxons_found[sample.ncbi_taxon_id]
        valid_samples.append(sample)

    return valid_samples, samples_without_taxon


def save_samples(db: Connection, samples: list[Sample]) -> Stats:
    totals = Stats()

    # Separate samples into existing and new based on whether they have a db_sample_id
    existing_samples, new_samples = [], []
    for sample in samples:
        (existing_samples if sample.db_sample_id else new_samples).append(sample)

    # Update existing samples in the database
    sql.update_samples(db, existing_samples)
    totals.increment("updated_existing", len(existing_samples))

    # Create new samples in the database and get their IDs
    new_sample_ids = sql.create_samples(db, new_samples)
    totals.increment("create_new", len(new_samples))
    # Update the db_sample_id for new samples
    if new_samples and new_sample_ids:  # Check if both lists are non-empty
        for sample, new_id in zip(new_samples, new_sample_ids):
            sample.db_sample_id = new_id
            sample.additinal_aliases = [replace(alias, sample_id=new_id) for alias in sample.additinal_aliases]

    # Now handle aliases after all samples have db_sample_id
    new_aliases = [alias for sample in samples for alias in sample.additinal_aliases]

    # filter out the existing aliases
    existing_aliases_names = {
        alias.name for alias in get_samples_by_sample_aliases(db, [alias.name for alias in new_aliases])
    }
    new_aliases = [alias for alias in new_aliases if alias.name not in existing_aliases_names]

    # filter out the duplications
    new_aliases = {alias.name: alias for alias in new_aliases}.values()

    # insert aliases now that we have all sample IDs
    aliases_ids = insert_sample_aliases(db, new_aliases)
    totals.increment("new_aliases_added", len(aliases_ids))

    pdst_records = [(sample, record) for sample in samples for record in sample.resistance_data]

    # Keep in mind, for the future reloads we will need to clear the previous data
    # Suggestion: use the PDST data accession key?
    sql.insert_pds_tests(db, pdst_records)

    totals.increment("inserted_pdst_items", len(pdst_records))
    return totals


def process_accession_based_samples(
    db: Connection, entrez: EntrezAdvanced, samples: list, page_num: int, pages_total: int, normalization_data: dict
) -> Stats:
    """Process samples based on their accession numbers."""
    page_totals = Stats()

    # Search for samples by accession
    accession_searches = [f"{sample[0]}[ACCESSION]" for sample in samples]
    accession_query = " OR ".join(accession_searches)
    accession_ids = set(id for result in entrez.esearch(DB.BIO_SAMPLE, accession_query) for id in result[0])

    missing_samples = len(samples) - len(accession_ids)

    if missing_samples:
        log.info(
            "[Page %s/%s] %s sample(s) were not returned by the BioSample API.", page_num, pages_total, missing_samples
        )

    if accession_ids:
        process_sample_batch(db, entrez, accession_ids, samples, page_totals, normalization_data, False)

    return page_totals


def process_date_based_samples(
    db: Connection, entrez: EntrezAdvanced, date_based_ids: set, normalization_data: dict
) -> Stats:
    """Process samples based on relative date."""
    page_totals = Stats()

    if date_based_ids:
        log.info("Start processing empty samples based on relative date")
        process_sample_batch(db, entrez, date_based_ids, None, page_totals, normalization_data, True)

    return page_totals


def process_sample_batch(
    db: Connection,
    entrez: EntrezAdvanced,
    ids: set,
    samples: list | None,
    page_totals: Stats,
    normalization_data: dict,
    is_empty: bool,
) -> None:
    """Process a batch of samples."""

    biosamples_xml = entrez.efetch(DB.BIO_SAMPLE, list(ids))
    initial_samples_gathered: list[Sample] = []

    tmp_package_id = get_or_create_temporary_ncbi_package(db)

    for biosample_xml in biosamples_xml:
        try:
            sample = extract_biosample(samples, biosample_xml, normalization_data, tmp_package_id, is_empty)
            if not sample:
                continue
            initial_samples_gathered.append(sample)
        except Exception:
            log.warning("Biosample XML: %s", xml_to_string(biosample_xml))
            raise

    # Process gathered samples
    if initial_samples_gathered:
        existing_samples = sql.get_samples_by_biosample_ids(db, [s.biosample_id for s in initial_samples_gathered])

        # Log warnings for existing samples
        for item in initial_samples_gathered:
            if item.biosample_id in existing_samples:
                log.warning(
                    f"Existing Biosample ID {item.biosample_id} in DB as "
                    f"{existing_samples[item.biosample_id]} while trying to update "
                    f"{item.db_sample_id}"
                )

        filtered_samples = [
            sample for sample in initial_samples_gathered if sample.biosample_id not in existing_samples
        ]

        valid_samples, samples_without_taxon = populate_taxon_ids(db, filtered_samples)
        page_totals.increment("samples_without_taxon", by=len(samples_without_taxon))
        page_totals.merge(save_samples(db, valid_samples))


def main(db: Connection, entrez: EntrezAdvanced, relative_date: int):
    log.info("Starting the samples data retrieval")

    page_num = 0
    last_id = 0
    totals = Stats()
    normalization_data = get_normalisation_data(db)

    total_count = sql.get_samples_with_missing_ncbi_data_count(db)
    pages_total = math.ceil(total_count / entrez.DEFAULT_PER_PAGE)

    log.info("Found %s samples to be updated", total_count)

    while True:
        page_totals = Stats()
        page_num += 1
        samples = sql.get_samples_with_missing_ncbi_data(db, per_page=entrez.DEFAULT_PER_PAGE, last_id=last_id)
        if not samples:
            break

        log.info(
            "[Page %s/%s] Got a page of samples with empty NCBI data (last id %s): %s. Head: %s...",
            page_num,
            pages_total,
            last_id,
            len(samples),
            samples[:3],
        )
        last_id = samples[-1][1]

        # Process accession-based samples
        acc_totals = process_accession_based_samples(db, entrez, samples, page_num, pages_total, normalization_data)
        page_totals.merge(acc_totals)

        log.info("[Page %s/%s] Result stats: %s", page_num, pages_total, page_totals)
        totals.merge(page_totals)

        db.commit()

    # Process date-based samples in batches of 1000
    log.info("Processing samples based on relative date %d...", relative_date)
    date_totals = Stats()

    for date_ids, page_num, pages_total in entrez.get_biosample_ids(relative_date):
        log.info(
            "[Date-based Page %s/%s] Processing batch of %d sample IDs from relative date search",
            page_num,
            pages_total,
            len(date_ids),
        )

        batch_totals = process_date_based_samples(db, entrez, date_ids, normalization_data)
        date_totals.merge(batch_totals)
        db.commit()

        log.info("[Date-based Page %s/%s] Batch stats: %s", page_num, pages_total, batch_totals)

    log.info("Completed processing date-based samples. Total stats: %s", date_totals)
    totals.merge(date_totals)

    db.commit()

    db.close()

    log.info("Total stats: %s", totals)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--db_host", help="AWS RDS database endpoint", default="127.0.0.1")
    parser.add_argument("--db_name", help="Database name", default="postgres")
    parser.add_argument("--db_user", help="Database user name (with AWS RDS IAM authentication)", default="postgres")
    parser.add_argument("--db_port", help="Database port", default=5433)
    parser.add_argument("--relative_date", type=int, default=30, help="Relative date")
    args = parser.parse_args()

    # TODO: Use the key arguments or better - a parameters store to retrieve the configs
    # Create a Secrets Manager client

    dep_entrez = EntrezAdvanced("afakeemail@gmail.com", "afakeapikey", True)

    dep_db = Connection(args.db_host, args.db_port, args.db_name, args.db_user)

    # Local debugging only
    set_global_debug(True)

    main(dep_db, dep_entrez, args.relative_date)
