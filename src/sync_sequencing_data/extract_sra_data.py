from typing import Optional

from src.common import logs
from src.common.stats import Stats
from src.entrez.base import find_text_or_none, xml_to_string
from src.sync_sequencing_data.models import SRARunResultFile

log = logs.create_logger(__name__)


class EntrezStructureChangedPossibly(Exception):
    pass


def get_global_biosample_accession(experiment_xml) -> Optional[str]:
    return find_text_or_none(
        experiment_xml,
        "EXPERIMENT/DESIGN/SAMPLE_DESCRIPTOR/IDENTIFIERS/EXTERNAL_ID[@namespace='BioSample']",
        "SAMPLE/IDENTIFIERS/EXTERNAL_ID[@namespace='BioSample']",
    )


def get_global_srs_accession(experiment_xml) -> Optional[str]:
    return find_text_or_none(experiment_xml, "EXPERIMENT/DESIGN/SAMPLE_DESCRIPTOR/IDENTIFIERS/PRIMARY_ID")


def get_sra_generic_data(experiment_xml):
    strategy = experiment_xml.find("EXPERIMENT/DESIGN/LIBRARY_DESCRIPTOR/LIBRARY_STRATEGY").text
    source = experiment_xml.find("EXPERIMENT/DESIGN/LIBRARY_DESCRIPTOR/LIBRARY_SOURCE").text
    selection = experiment_xml.find("EXPERIMENT/DESIGN/LIBRARY_DESCRIPTOR/LIBRARY_SELECTION").text
    platform = list(experiment_xml.find("EXPERIMENT/PLATFORM"))[0].tag
    machine = experiment_xml.find("EXPERIMENT/PLATFORM/" + platform + "/INSTRUMENT_MODEL").text
    library_layout = list(experiment_xml.find("EXPERIMENT/DESIGN/LIBRARY_DESCRIPTOR/LIBRARY_LAYOUT"))[0].tag
    return strategy, source, selection, platform, machine, library_layout


def extract_sra_data(experiment_xml) -> tuple[list[SRARunResultFile], Stats]:
    totals = Stats()
    new_items: list[SRARunResultFile] = []

    # INFO: Skipping some experiments because of uncertainty
    experiment_id = find_text_or_none(experiment_xml, "EXPERIMENT/IDENTIFIERS/PRIMARY_ID")
    if experiment_id in ["SRX066538"]:
        log.warning(
            "Skipped experiment SRX066538 because we don't know what to do with it :/ Multiple members per run?!"
        )
        return new_items, totals

    (strategy, source, selection, platform, machine, library_layout) = get_sra_generic_data(experiment_xml)
    for run in experiment_xml.findall("RUN_SET/RUN"):
        library_name = run.find("IDENTIFIERS/PRIMARY_ID").text

        biosample_accession = find_text_or_none(run, "Pool/Member/IDENTIFIERS/EXTERNAL_ID[@namespace='BioSample']")
        if biosample_accession is None:
            biosample_accession = get_global_biosample_accession(experiment_xml)
        assert biosample_accession

        srs_accession = find_text_or_none(run, "Pool/Member/IDENTIFIERS/PRIMARY_ID")
        if srs_accession is None:
            srs_accession = get_global_srs_accession(experiment_xml)
        assert srs_accession

        # Import sra file only where semantic_name="run"
        processed_files = [
            sra_file for sra_file in run.findall("SRAFiles/SRAFile") if
            sra_file.attrib["semantic_name"] == "SRA Normalized"
        ] or [
            sra_file for sra_file in run.findall("SRAFiles/SRAFile") if
            sra_file.attrib["semantic_name"] == "SRA Lite"
        ]

        if not processed_files:
            # run the data contract change check to possibly notify the system we have to update the code
            possibly_processed_files = [
                sra_file for sra_file in run.findall("SRAFiles/SRAFile") if
                "." not in sra_file.attrib["filename"] or sra_file.attrib["sratoolkit"] == "1"
            ]
            if possibly_processed_files:
                log.warning(
                    "Found a run where we have no processed file indicated,"
                    " but there are some indicators the file is there."
                    " Worth checking out? Exp ID: %s XML: %s",
                    experiment_id, xml_to_string(experiment_xml))
                totals.increment("skipped_no_runs_uploaded_suspicious_protocol_changes")

            totals.increment("skipped_no_runs_uploaded")
            continue
        assert len(processed_files) == 1
        processed_file = processed_files[0]

        original_files_md5 = [
            sra_file.attrib["md5"]
            for sra_file in run.findall("SRAFiles/SRAFile")
            if sra_file.attrib["supertype"] == "Original"
        ]

        # TODO: Now we are allowing to insert the sequencing data w/o any originals,
        #     We still might need to check the db behavior, but it think it will do just fine
        # if not original_files_md5:
        #     totals.increment("skipped_no_originals_uploaded")
        #     continue

        # Use set to deduplicate the checksums
        # It could happen sometimes, we are not sure why and when
        if len(set(original_files_md5)) != len(original_files_md5):
            log.warning(
                "Duplicated md5 checksums found within a single experiment, removing dupes. Worth checking out? Exp ID: %s XML: %s",
                experiment_id, xml_to_string(experiment_xml))
            original_files_md5 = list(set(original_files_md5))

        assert all(f is not None for f in original_files_md5)

        new_items.append(
            SRARunResultFile(
                db_id=None,
                file_name=processed_file.attrib["filename"],
                db_sample_id=None,
                db_aliases_created=False,
                biosample_accession=biosample_accession,
                srs_accession=srs_accession,
                md5_hashes=original_files_md5,
                library_name=library_name,
                strategy=strategy,
                source=source,
                selection=selection,
                platform=platform,
                machine=machine,
                library_layout=library_layout,
            )
        )
        totals.increment("sra_file_extracted")
    return new_items, totals
