import argparse

from src.common import logs
from src.common.logs import set_global_debug
from src.common.stats import Stats
from src.db.database import Connection
from src.entrez.advanced import EntrezAdvanced
from src.entrez.base import DB, xml_to_string
from src.sync_sequencing_data import sql
from src.sync_sequencing_data.extract_sra_data import extract_sra_data
from src.sync_sequencing_data.save_sra_data import save_sra_data

log = logs.create_logger(__name__)


def main(db: Connection, entrez: EntrezAdvanced, relative_date: int, bioproject_accession: str):
    search = " reldate " + str(relative_date)
    if bioproject_accession:
        search = " BioProject " + bioproject_accession
    log.info("Starting the sequencing data synchronization with"+ search)
    totals = Stats()

    tmp_package_id = sql.get_or_create_temporary_ncbi_package(db)

    for ids_page, page_num, pages_total in entrez.get_sra_ids(relative_date, bioproject_accession):
        log.info("[Page %s/%s] Processing a new page...", page_num, pages_total)

        biosamples_xml = entrez.efetch(DB.SRA, ids_page)

        page_totals = Stats()
        sra_items = []
        for experiment_xml in biosamples_xml.findall("EXPERIMENT_PACKAGE"):
            try:
                items, stats = extract_sra_data(experiment_xml)
            except Exception:
                log.warning("EXPERIMENT XML: %s", "".join(xml_to_string(experiment_xml).split("\n")))
                raise
            page_totals.merge(stats)
            sra_items.extend(items)

        stats = save_sra_data(db, tmp_package_id, sra_items)
        page_totals.merge(stats)

        log.info("[Page %s/%s] Page stats: %s", page_num, pages_total, page_totals)
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
    parser.add_argument("--relative_date", type=int, default=30, help="Relative date")
    parser.add_argument("--bioproject_accession", type=str, default="", help="BioProject accession")
    
    args = parser.parse_args()

    dep_db = Connection(args.db_host, args.db_port, args.db_name, args.db_user)

    # TODO: Use the key arguments or better - a parameters store to retrieve the configs
    dep_entrez = EntrezAdvanced("afakeemail@gmail.com", "afakeapikey", True)

    # Local debugging only
    # dep_db.user = "db_userx"
    # dep_db.host = "database-1.cuojmpjkhvot.us-east-1.rds.amazonaws.com"
    # dep_db.port = "5432"

    dep_db.user = "fdxmainuatuser"
    dep_db.host = "fdxmainuatdefault.cyelkpwgr0gv.us-east-1.rds.amazonaws.com"
    dep_db.port = "5432"

    dep_db.ensure_password_resolution()
    dep_db.host = args.db_host
    dep_db.port = args.db_port

    dep_db.name = "fdxmainuatdb"
    args.relative_date = 100 * 365
    set_global_debug(True)

    main(dep_db, dep_entrez, int(args.relative_date), str(args.bioproject_accession))
