import argparse
import math

from src.common import logs
from src.common.stats import Stats
from src.db.database import Connection
from src.entrez.advanced import EntrezAdvanced
from src.entrez.base import DB, xml_to_string
from src.sync_projects import sql
from src.sync_sequencing_data.sql import get_or_create_temporary_ncbi_package

log = logs.create_logger(__name__)


def link_to_bioproject(db: Connection, entrez: EntrezAdvanced, linked_object: str):
    log.info("Starting the bioprojects synchronization for %s objects", linked_object)

    tmp_package_id = get_or_create_temporary_ncbi_package(db)

    page_num = 0
    last_id = 0
    totals = Stats()
    entrez.DEFAULT_PER_PAGE = 1000

    total_count = sql.get_object_without_project_imported_count(
        db, tmp_package_id, linked_object
    )

    log.info(
        "Found %s %s object(s) to be attached to the bioprojects",
        total_count,
        linked_object,
    )

    pages_total = math.ceil(total_count / entrez.DEFAULT_PER_PAGE)

    while True:
        page_num += 1

        object = sql.get_objects_without_project_imported(
            db,
            tmp_package_id,
            per_page=entrez.DEFAULT_PER_PAGE,
            last_id=last_id,
            obj=linked_object,
        )
        if not object:
            break

        log.info(
            "[Page %s/%s] Got a page of %s (last id %s): %s. Head: %s...",
            page_num,
            pages_total,
            linked_object,
            last_id,
            len(object),
            object[:3],
        )
        last_id = object[-1][0]

        initial_aliases_gathered = {}

        # if we are doing sample alias we need to search again for
        # the biosample_id because we don't have it!
        # so we create a matching dictionnary biosample id -> biosample accession
        # remember that we can't rely on the biosample id from the submission_sample table
        # because we have md5checksum merged ! so we are lacking biosample ids in some cases
        if linked_object == "samplealias":
            biosample_ids: list[int] = [
                int(id)
                for result in entrez.esearch(
                    DB.BIO_SAMPLE,
                    " OR ".join([aliases[1] + "[ACCESSION]" for aliases in object]),
                )
                for id in result[0]
            ]
            if biosample_ids:
                biosamples_xml = entrez.efetch(DB.BIO_SAMPLE, biosample_ids)

            for biosample_xml in biosamples_xml:
                try:
                    initial_aliases_gathered[int(biosample_xml.attrib["id"])] = (
                        "%" + biosample_xml.attrib["accession"] + "%"
                    )
                except Exception:
                    log.warning("Biosample XML: %s", xml_to_string(biosample_xml))
                    raise

        # when doing the sample, we elink using the biosample id directly returned from the sql query
        # however when doing the samplealiases, we use the dictionnary keys
        object_bioproject_matches = entrez.elink(
            DB.BIO_SAMPLE,
            DB.BIO_PROJECT,
            list(initial_aliases_gathered.keys())
            if initial_aliases_gathered
            else [sample[1] for sample in object],
            link="biosample_bioproject_all",
        )

        if not object_bioproject_matches:
            continue

        page_totals = Stats()
        # Reversing the dictionnary so that we now have
        # the list of biosample id (for sample)/biosample accession (for samplealias) as value, the bioproject id as key

        bioproject_object_reversed = {}
        for object_id, project_id in object_bioproject_matches.items():
            if project_id not in [
                # Ref FIND-689. 514245 has a lot of data, we are unable to fetch it from API, it fails with timeout
                #   NCBI admins told us they won't be fixing it any time soon, let's remove it from sync for now
                514245
            ]:
                # When doing samplealias, we construct a list of biosample accessions using the matching dict
                # When doing sample, the list can be biosample ids
                bioproject_object_reversed.setdefault(project_id, []).append(
                    initial_aliases_gathered.get(object_id, object_id)
                )

        # Efetch on the bioproject to get full name, for creation
        projects = entrez.get_projects(*list(set(bioproject_object_reversed.keys())))

        for project in projects:
            # TODO: insert the bioproject name as well!!! EDIT (sacha): not sure about this TODO?

            # Creating package or getting its id if it exists
            db_package_id = sql.get_or_create_data_package_by_ncbi_id(
                db, project.id, f"[{project.name}] {project.title}"
            )
            page_totals.increment("bioprojects_synced")

            # now choose correct function
            if linked_object == "sample":
                samples_updated, pdst_updated = sql.move_sample_data_to_new_package(
                    db, db_package_id, bioproject_object_reversed[project.id]
                )
                page_totals.increment("samples_updated", samples_updated)
                page_totals.increment("pdst_updated", pdst_updated)

            elif linked_object == "samplealias":
                aliases_updated = sql.move_alias_data_to_package(
                    db, db_package_id, bioproject_object_reversed[project.id]
                )
                page_totals.increment("aliases_updated", aliases_updated)

        log.info("[Page %s/%s] Result stats: %s", page_num, pages_total, page_totals)
        totals.merge(page_totals)

        db.commit()

    log.info("Total stats: %s", totals)


def main(db: Connection, entrez: EntrezAdvanced):
    log.info("Starting the bioprojects synchronization")

    link_to_bioproject(db, entrez, "sample")

    link_to_bioproject(db, entrez, "samplealias")

    db.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--db_host", help="AWS RDS database endpoint", default="127.0.0.1")
    parser.add_argument("--db_name", help="Database name", default="postgres")
    parser.add_argument("--db_user", help="Database user name (with AWS RDS IAM authentication)", default="postgres")
    parser.add_argument("--db_port", help="Database port", default=5433)
    args = parser.parse_args()

    # TODO: Use the key arguments or better - a parameters store to retrieve the configs
    dep_entrez = EntrezAdvanced("afakeemail@gmail.com", "afakeapikey", True)

    dep_db = Connection(args.db_host, args.db_port, args.db_name, args.db_user)
    main(dep_db, dep_entrez)
