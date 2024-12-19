import argparse

from src.common import logs
from src.db.database import Connection

log = logs.create_logger(__name__)


def main(db: Connection):
    log.info("Starting the NCBI data wipe")

    cursor = db.cursor()

    # TODO: We need to set up the proper cascades...
    cursor.execute(
        """
        DELETE FROM public.submission_pdstest t
    
        USING public.submission_sample s
        WHERE s.id = t.sample_id AND s.origin='NCBI';
        
        DELETE FROM public.submission_sequencingdatahash t
        USING public.submission_sequencingdata s
        WHERE s.id = t.sequencing_data_id AND data_location='NCBI';
        
        DELETE FROM public.submission_sequencingdata WHERE data_location='NCBI';
        
        DELETE FROM public.submission_samplealias t
        USING public.submission_sample s
        WHERE s.id = t.sample_id AND s.origin='NCBI';
        
        DELETE FROM public.submission_sample WHERE origin='NCBI';
        DELETE FROM public.submission_package WHERE origin='NCBI';
        
        VACUUM;
    """
    )

    db.commit()
    db.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--db_host", help="AWS RDS database endpoint", default="127.0.0.1")
    parser.add_argument("--db_name", help="Database name", default="postgres")
    parser.add_argument("--db_user", help="Database user name (with AWS RDS IAM authentication)", default="postgres")
    parser.add_argument("--db_port", help="Database port", default=5433)
    args = parser.parse_args()

    db = Connection(args.db_host, args.db_port, args.db_name, args.db_user)
    main(db)
