from src.common import logs
from src.sync_samples.models import NormalizationData, ResistanceRecord

log = logs.create_logger(__name__)


def extract_resistance_data(
    biosample_xml, normalization_data: NormalizationData
) -> list[ResistanceRecord]:
    table = biosample_xml.findall("Description/Comment/Table")

    records = []

    for i in table:
        if not i.attrib["class"].startswith("Antibiogram.mycobacterial"):
            continue

        headers = i.findall("Header/Cell")
        columns = {
            headers[y].text: y
            for y in range(len(headers))
            if headers[y].text
            in (
                "Antibiotic",
                "Resistance phenotype",
                "DST Method",
                "Critical Concentration",
            )
        }
        for test in i.findall("Body/Row"):
            cells = test.findall("Cell")
            drug_name = (
                cells[columns["Antibiotic"]]
                .text.replace("rifampin", "rifampicin")
                .replace("fluoroquinolone", "fluoroquinolones")
                .capitalize()
                .strip()
            )
            concentration = cells[columns["Critical Concentration"]].text.strip()
            result = cells[columns["Resistance phenotype"]].text[0].capitalize()
            if cells[columns["DST Method"]].text.strip() == "Nitrate reductase assay":
                medium = ""
                method = "Nitrate reductase assay"
            elif cells[columns["DST Method"]].text.strip() == "Agar proportion":
                medium = "Agar"
                method = "Proportions"
            elif (
                cells[columns["DST Method"]].text.strip()
                == "Lowenstein-Jensen, resistance ratio"
            ):
                medium = "LJ"
                method = "Resistance Ratio"
            elif (
                cells[columns["DST Method"]].text.strip()
                == "Lowenstein-Jensen, absolute concentration"
            ):
                medium = "LJ"
                method = ""
            elif cells[columns["DST Method"]].text.strip() in ("BACTEC460", "MGIT960"):
                medium = "MGIT"
                method = ""
            else:
                medium = cells[columns["DST Method"]].text.strip().replace(" ", "")
                method = ""

            record = ResistanceRecord(
                db_id=None,
                accession_id=i.attrib.get("accession", ""),
                drug=normalization_data.get_drug_by_name(drug_name),
                method=normalization_data.get_method_by_name(method),
                medium=normalization_data.get_medium_by_name(medium),
                concentration=concentration,
                result=result,
            )

            if record.drug is None:
                log.warning(
                    "Cannot find a drug %s, skipping the PDST record", drug_name
                )
                continue
            records.append(record)
    return records
