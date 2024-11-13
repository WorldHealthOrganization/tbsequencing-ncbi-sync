import argparse
import math

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
from src.sync_sequencing_data.sql import get_samples_by_sample_aliases, insert_sample_aliases

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

    new_aliases = [alias for sample in samples for alias in sample.additinal_aliases]

    # filter out the existing aliases
    existing_aliases_names = {
        alias.name
        for alias in get_samples_by_sample_aliases(db, [alias.name for alias in new_aliases])
    }
    new_aliases = [alias for alias in new_aliases if alias.name not in existing_aliases_names]

    # filter out the duplications
    new_aliases = {alias.name: alias for alias in new_aliases}.values()

    # insert it
    aliases_ids = insert_sample_aliases(db, new_aliases)
    totals.increment("new_aliases_added", len(aliases_ids))

    sql.update_samples(db, samples)
    totals.increment("updated_samples", len(samples))

    pdst_records = [(sample, record) for sample in samples for record in sample.resistance_data]

    # Keep in mind, for the future reloads we will need to clear the previous data
    # Suggestion: use the PDST data accession key?
    sql.insert_pds_tests(db, pdst_records)

    totals.increment("inserted_pdst_items", len(pdst_records))
    return totals


def main(db: Connection, entrez: EntrezAdvanced):
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

        ids: list[int] = [
            id
            for result in entrez.esearch(DB.BIO_SAMPLE, " OR ".join([name[0] + "[ACCESSION]" for name in samples]))
            for id in result[0]
        ]

        missing_samples = len(samples) - len(ids)

        if missing_samples:
            log.info(
                "[Page %s/%s] %s sample(s) were not returned by the BioSample API.",
                page_num,
                pages_total,
                missing_samples,
            )

        if ids:
            biosamples_xml = entrez.efetch(DB.BIO_SAMPLE, ids)

            initial_samples_gathered: list[Sample] = []
            for biosample_xml in biosamples_xml:
                try:
                    sample = extract_biosample(samples, biosample_xml, normalization_data)
                    if sample:
                        initial_samples_gathered.append(sample)
                except Exception:
                    log.warning("Biosample XML: %s", xml_to_string(biosample_xml))
                    raise

            # consistency remediation
            existing_samples = sql.get_samples_by_biosample_ids(db, [s.biosample_id for s in initial_samples_gathered])
            for item in initial_samples_gathered:
                if item.biosample_id in existing_samples:
                    log.warning(f"Existing Biosample ID {item.biosample_id} in DB as {existing_samples[item.biosample_id]} while trying to update {item.db_sample_id}")
            initial_samples_gathered = [s for s in initial_samples_gathered if s.biosample_id not in existing_samples]


            valid_samples, samples_without_taxon = populate_taxon_ids(db, initial_samples_gathered)
            page_totals.increment("samples_without_taxon", by=len(samples_without_taxon))

            page_totals.merge(save_samples(db, valid_samples))

        log.info("[Page %s/%s] Result stats: %s", page_num, pages_total, page_totals)
        totals.merge(page_totals)

        db.commit()
    db.close()

    log.info("Total stats: %s", totals)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--db_host", help="AWS RDS database endpoint", default="127.0.0.1")
    parser.add_argument("--db_name", help="Database name", default="postgres")
    parser.add_argument("--db_user", help="Database user name (with AWS RDS IAM authentication)", default="postgres")
    parser.add_argument("--db_port", help="Database port", default=5433)
    args = parser.parse_args()

    # TODO: Use the key arguments or better - a parameters store to retrieve the configs
    # Create a Secrets Manager client

    dep_entrez = EntrezAdvanced("afakeemail@gmail.com", "afakeapikey", True)

    dep_db = Connection(args.db_host, args.db_port, args.db_name, args.db_user)

    # Local debugging only
    set_global_debug(True)

    main(dep_db, dep_entrez)
