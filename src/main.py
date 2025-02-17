import argparse
import boto3
import json

# import sentry_sdk

from src.common.logs import set_global_debug
from src.db.database import Connection
from src.entrez.advanced import EntrezAdvanced
from src.sync_projects.main import main as sync_projects
from src.sync_samples.main import main as sync_samples
from src.sync_sequencing_data.main import main as sync_sequencing_data
from src.sync_taxonomy.main import main as sync_taxonomy

# sentry_sdk.init(
#     dsn="",
#     # Set traces_sample_rate to 1.0 to capture 100%
#     # of transactions for performance monitoring.
#     # We recommend adjusting this value in production.
#     traces_sample_rate=0,
# )


def main(args):
    set_global_debug(args.debug)

    dep_db = Connection(args.db_host, args.db_port, args.db_name, args.db_user, args.db_password)

    # No need for the NCBI secret if we are updating the taxonomy
    if args.section == "taxonomy":
        sync_taxonomy(dep_db)
    else:
        if args.ncbi_email and args.ncbi_key:
            dep_entrez = EntrezAdvanced(args.ncbi_email, args.ncbi_key, args.caching)
        else:
            session = boto3.session.Session()
            client = session.client(service_name="secretsmanager")
            get_secret_value_response = client.get_secret_value(SecretId=args.ncbi_secret_arn)
            secret = json.loads(get_secret_value_response["SecretString"])

            dep_entrez = EntrezAdvanced(secret["email"], secret["api_key"], args.caching)

        if args.section == "sequencing":
            sync_sequencing_data(dep_db, dep_entrez, int(args.relative_date), str(args.bioproject_accession))
        elif args.section == "samples":
            sync_samples(dep_db, dep_entrez, int(args.relative_date))
        elif args.section == "projects":
            sync_projects(dep_db, dep_entrez)
        else:
            raise Exception(f"Unknown section selected: {args.section}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--db_host", help="AWS RDS database endpoint", default="127.0.0.1")
    parser.add_argument("--db_name", help="Database name", default="postgres")
    parser.add_argument("--db_user", help="Database user name (with AWS RDS IAM authentication)", default="postgres")
    parser.add_argument("--db_password", help="Database password or RDS authentication switch", default="RDS")
    parser.add_argument("--db_port", type=int, help="Database port", default=5433)
    search_group = parser.add_argument_group(
        "Search option", "Define the search for initiating the sequencing data synchronization."
    )
    search_exclusive = search_group.add_mutually_exclusive_group()
    search_exclusive.add_argument("--bioproject_accession", type=str, default="", help="BioProject accession")
    search_exclusive.add_argument("--relative_date", type=int, default=0, help="Relative date")
    parser.add_argument("--ncbi_secret_arn", help="Secret ARN with email and API key values for NCBI", default="")
    parser.add_argument("--ncbi_email", default="", help="Email adress for NCBI registration")
    parser.add_argument("--ncbi_key", default="", help="API key for NCBI registration")
    parser.add_argument("--section", help="Current section to get executed")
    parser.add_argument("--set_debug", type=bool, default=False, help="Enable/disable debug logging")
    parser.add_argument("--debug", default=False, action="store_true", help="Enable debug logging")
    parser.add_argument("--caching", default=False, action="store_true", help="Enable local caching")

    args = parser.parse_args()

    main(args)
