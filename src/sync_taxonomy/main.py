import argparse
import os
import subprocess

from src.common import logs
from src.db.database import Connection

log = logs.create_logger(__name__)

loader_script_url = "https://raw.githubusercontent.com/biosql/biosql/master/scripts/load_ncbi_taxonomy.pl"
tax_dump_url = "ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz"


def main(db: Connection):
    if not os.path.exists("tmp/taxonomy_loader.pl"):
        log.info("Creating the file structure...")
        os.makedirs("tmp/taxdata", exist_ok=True)

        log.info("Downloading the executable script...")
        subprocess.run(["wget", "--quiet", loader_script_url, "-O", "taxonomy_loader.pl"], check=True, cwd="tmp")

    log.info("Downloading the data...")
    if not os.path.exists("tmp/taxdata/taxdump.tar.gz"):
        subprocess.run(["wget", "--quiet", tax_dump_url, "-O", "taxdump.tar.gz"], check=True, cwd="tmp/taxdata")
        subprocess.run(["tar", "xf", "taxdump.tar.gz"], check=True, cwd="tmp/taxdata")

    log.info("Resolving the RDS password...")
    db.ensure_password_resolution()

    log.info("Running the NCBI Taxonomy import...")
    subprocess.run(
        [
            "perl",
            "taxonomy_loader.pl",
            "--driver",
            "Pg",
            "--host",
            db.host,
            "--dbname",
            db.name,
            "--dbuser",
            db.user,
            "--port",
            str(db.port),
            "--dbpass",
            db.password,
            "--verbose=2",
        ],
        check=True,
        cwd="tmp",
    )
    log.info("Done!")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--db_host", help="AWS RDS database endpoint", default="127.0.0.1")
    parser.add_argument("--db_name", help="Database name", default="postgres")
    parser.add_argument("--db_user", help="Database user name (with AWS RDS IAM authentication)", default="postgres")
    parser.add_argument("--db_port", help="Database port", default=5433)
    args = parser.parse_args()

    dep_db = Connection(args.db_host, args.db_port, args.db_name, args.db_user)
    main(dep_db)
