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
    get_positive_biosample_ids,
    get_biosample_ids_from_samplealias,
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
    # (sacha) save_samples is called separately for each sync logic (accession-based, date-based)
    # (sacha) so we never have both types of samples in the same list
    existing_samples, new_samples = [], []

    for sample in samples:
        # add check here that samples should not go into new sample if their alias
        # already exist
        if sample.db_sample_id:
            existing_samples.append(sample)
        elif get_samples_by_sample_aliases(db, [alias.name for alias in sample.additional_aliases]):
            log.warning(
                "Detected biosample %s which was merged to another biosample already. " 
                "Skipping insertion.",
                sample.biosample_id
            )
            totals.increment("biosample_already_merged_by_md5")
            pass
        else:
            new_samples.append(sample)

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
            sample.additional_aliases = [replace(alias, sample_id=new_id) for alias in sample.additional_aliases]

    # Now handle aliases after all samples have db_sample_id
    new_aliases = [alias for sample in samples for alias in sample.additional_aliases]

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

    # First filter biosample aliases and get their corresponding IDs
    biosample_aliases = [alias for alias in new_aliases if alias.alias_type.lower() == DB.BIO_SAMPLE.value]
    biosample_ids = [
        aliases_ids[i] for i, alias in enumerate(new_aliases) if alias.alias_type.lower() == DB.BIO_SAMPLE.value
    ]

    # Create map using sample_id for filtered biosample aliases
    biosample_alias_map = {alias.sample_id: alias_id for alias, alias_id in zip(biosample_aliases, biosample_ids)}

    # Update samples using sample_id
    for sample in samples:
        if sample.alias_id is None and sample.db_sample_id in biosample_alias_map:
            sample.alias_id = biosample_alias_map[sample.db_sample_id]

    pdst_records = [(sample, record) for sample in samples for record in sample.resistance_data if sample.alias_id]

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
        # is empty is false because the sample row of these exist already
        # (inserted during sync-sec)
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
        # Process accession-based samples
        # We fetch samples that were inserted during seq-sync,
        # which have sample aliases inserted already
        # But their biosample_id value is still null
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

        # We update these samples, filling up their biosample_id value
        # and other metadata, if available
        acc_totals = process_accession_based_samples(db, entrez, samples, page_num, pages_total, normalization_data)
        page_totals.merge(acc_totals)

        log.info("[Page %s/%s] Result stats: %s", page_num, pages_total, page_totals)
        totals.merge(page_totals)

        db.commit()

    # Process date-based samples in batches of 1000
    # These are the samples that have not been inserted during seq-sync
    log.info("Starting the samples data retrieval")
    log.info("Processing samples based on relative date %d...", relative_date)
    date_totals = Stats()

    # Lets try to exclude biosamples we already have in the db from the search
    known_biosample_from_sample = get_positive_biosample_ids(db)

    # In the case of samples merged by md5sum, the biosample id 
    # does not exist in the database but we already have the alias
    # So we need to exclude these from the sync as well
    # Otherwise we would insert these new biosample ids 
    # but they wouldn't be linked to any sample alias, e.g. :   
    # select count(*) from submission_sample ss left join
    # submission_samplealias ssa on ssa.sample_id=ss.id 
    # where biosample_id is not null and ssa.id is null;

    # first we can use the fact that for biosamples submitted at NCBI
    # the biosample alias is simply "SAMN"+biosample_id

    known_biosample_ids_from_alias = get_biosample_ids_from_samplealias(db)

    known_biosample_ids = set(known_biosample_from_sample) | set(known_biosample_ids_from_alias)

    for date_ids, page_num, pages_total in entrez.get_biosample_ids(relative_date):
        log.info(
            "[Date-based Page %s/%s] Processing batch of %d sample IDs from relative date search",
            page_num,
            pages_total,
            len(date_ids),
        )


        # Make sure items in both list are all ints
        processing = list(
            set([int(x) for x in date_ids])-known_biosample_ids
        )

        log.info(
            "Only processing %s samples from batch after excluding already known",
            len(processing)
        )

        batch_totals = process_date_based_samples(
            db,
            entrez,
            processing,
            normalization_data
            )
        
        date_totals.merge(batch_totals)
        db.commit()

        log.info("[Date-based Page %s/%s] Batch stats: %s", page_num, pages_total, batch_totals)

    log.info("Completed processing date-based samples. Total stats: %s", date_totals)
    totals.merge(date_totals)

    db.close()

    log.info("Total stats: %s", totals)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--db_host", help="AWS RDS database endpoint", default="127.0.0.1")
    parser.add_argument("--db_name", help="Database name", default="postgres")
    parser.add_argument("--db_user", help="Database user name (with AWS RDS IAM authentication)", default="postgres")
    parser.add_argument("--db_port", help="Database port", default=5433)
    parser.add_argument("--relative_date", type=int, default=30, help="Relative date")
    parser.add_argument("--db_password", help="Database password or RDS authentication switch", default="RDS")
    parser.add_argument("--ncbi_email", default="", help="Email adress for NCBI registration")
    parser.add_argument("--ncbi_key", default="", help="API key for NCBI registration")
    parser.add_argument("--debug", action=argparse.BooleanOptionalAction, help="Logging level")

    args = parser.parse_args()

    # TODO: Use the key arguments or better - a parameters store to retrieve the configs
    # Create a Secrets Manager client

    # TODO: Use the key arguments or better - a parameters store to retrieve the configs
    if args.ncbi_email and args.ncbi_key:
        dep_entrez = EntrezAdvanced(args.ncbi_email, args.ncbi_key, True)
    else:
        dep_entrez = EntrezAdvanced("afakeemail@gmail.com", "afakeapikey", True)

    dep_db = Connection(args.db_host, args.db_port, args.db_name, args.db_user, args.db_password)

    # Local debugging only
    set_global_debug(args.debug)

    main(dep_db, dep_entrez, args.relative_date)
