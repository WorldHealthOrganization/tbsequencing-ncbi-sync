from datetime import datetime
from typing import Optional

from src.common import logs
from src.sync_samples import extractors
from src.sync_samples.extract_resistance_data import NormalizationData, extract_resistance_data
from src.sync_samples.sql import Sample
from src.sync_sequencing_data.models import NewSampleAlias

log = logs.create_logger(__name__)


def extract_biosample(
    samples, biosample_xml, normalization_data: NormalizationData, tmp_package_id: int, is_empty: bool = False
) -> Optional[Sample]:
    biosample_id: str = biosample_xml.attrib["id"]

    organism_name = biosample_xml.find("Description/Organism").attrib["taxonomy_name"]
    organism_id = int(biosample_xml.find("Description/Organism").attrib["taxonomy_id"])
    if "mycobacterium" not in organism_name.lower():
        log.warning(
            f"Found non-mycobacterium data as biosample id={biosample_id}, should we reconsider the query?"
            f" organism_name={organism_name}"
        )
        return None

    ################################################
    # Collect the biosample information
    ################################################

    sampling_date = None
    lower_bound_date, upper_bound_date = extractors.get_collection_date(biosample_xml)
    if lower_bound_date and upper_bound_date:
        sampling_date = extractors.format_for_dbfield(lower_bound_date, upper_bound_date)

    submission_date = datetime.strptime(biosample_xml.attrib["submission_date"], "%Y-%m-%dT%H:%M:%S.%f").date()

    longitude, latitude = extractors.get_latitude_longitude(biosample_xml)
    country_id, geo_loc_name = extractors.get_country(biosample_xml)

    isolation_source = extractors.get_isolation_source(biosample_xml)

    ##################################################
    # Collect all sample alias information
    ##################################################

    srs_name = ""

    sample_aliases = []
    for id in biosample_xml.findall("Ids/Id"):
        sample_aliases.append((id.text, id.attrib.get("db", "") or "NCBI_IDS", id.attrib.get("db_label", "")))
        if id.attrib.get("db", "") == "SRA":
            srs_name = id.text
            
    # Harmonized sample name is the sample name as provided by the submitter
    # Sometimes it's not included in the Ids bloc
    harmonized_name = biosample_xml.find('Attributes/Attribute[@harmonized_name="sample_name"]')
    if harmonized_name is not None:
        sample_aliases.append((harmonized_name.text, "INSDC", ""))

    # If the sample entry does not exist already
    if is_empty:
        alias_id = db_sample_id = None
        package_id = tmp_package_id
        biosample_accession: str = biosample_xml.attrib["accession"]

        # We need to make sure aliases insertion is consistent with samples that were
        # pre-inserted during seq-sync
        # During seq-sync, we insert normal sample aliases from BioSample and SRS
        # and then for these we inserted concatenated strings (see below)
        sample_aliases.append(
            (biosample_accession, "CustomBioSample", "")
        )

        # For consistency with biosamples inserted after seq-sync
        # we also include the composite alias "biosample__srs"
        if srs_name:
            sample_aliases.append(
                (srs_name, "CustomSRA", "")
            )

        aliases = [
            NewSampleAlias(
                tmp_package_id=package_id,
                sample_id=db_sample_id,
                name=alias[0] if alias[1] in ("SRA", "BioSample") else f"{biosample_accession}__{alias[0]}",
                # I am not sure that the SRS alias will exist as we are searching
                # for samples that do not have sequencing data associated
                alias_type="SRS" if alias[1] == "SRA" else alias[1].replace("CustomBioSample", "BioSample").replace("CustomSRA", "SRA"),
                alias_label="Sample name" if alias[1] in ("SRA", "BioSample") else alias[2],
            )
            for alias in sample_aliases
        ]
    else:
        # The sample row exist already, fetch it
        # We search the list of samples that we retrieved from the db
        # by the alias value retrieved from the NCBI XML

        biosample_name, db_sample_id, package_id, alias_id = next(
            (biosample_name, matched_sample_id, package_id, alias_id)
            for biosample_name, matched_sample_id, package_id, alias_id in samples
            if any(biosample_name == alias[0] for alias in sample_aliases)
        )
        aliases = [
            NewSampleAlias(
                tmp_package_id=package_id,
                sample_id=db_sample_id,
                name=f"{biosample_name}__{alias[0]}",
                alias_type=alias[1],
                alias_label=alias[2],
            )
            for alias in sample_aliases
        ]

    sample = Sample(
        alias_id=alias_id,
        db_sample_id=db_sample_id,
        package_id=package_id,
        biosample_id=int(biosample_id),
        db_taxon_id=None,
        ncbi_taxon_id=organism_id,
        submission_date=submission_date,
        sampling_date=sampling_date,
        latitude=latitude,
        longitude=longitude,
        country_id=country_id,
        geo_loc_name=geo_loc_name,
        isolation_source=isolation_source,
        resistance_data=[],
        additional_aliases=aliases,
    )

    # Collect additional aliases
    sample.resistance_data = extract_resistance_data(biosample_xml, normalization_data)
    return sample
