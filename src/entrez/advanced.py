from typing import Generator

from src.common.logs import create_logger
from src.entrez.base import DB, EFetchResult, EntrezBase, xml_to_string
from src.entrez.models import BioProject

log = create_logger(__name__)


class EntrezAdvanced(EntrezBase):
    def get_biosample(self, *ids) -> EFetchResult:
        return self.efetch(DB.BIO_SAMPLE, list(ids))

    def get_sra_ids(self, reldate: int, biopro: str) -> Generator[tuple[list[int], int, int], None, None]:
        if biopro:
            return self.esearch(DB.SRA, biopro + "[BIOPROJECT]")
        return self.esearch(DB.SRA, "MYCOBACTERIUM[ORGN]", reldate=reldate)

    def get_biosample_ids(self, reldate: int) -> Generator[tuple[list[int], int, int], None, None]:
        return self.esearch(DB.BIO_SAMPLE, "MYCOBACTERIUM[ORGN]", reldate=reldate)

    def get_projects(self, *ids) -> list[BioProject]:
        if not ids:
            return []

        elements = self.efetch(DB.BIO_PROJECT, list(ids))

        results: list[BioProject] = []
        for item in elements:
            try:
                name = item.find("Project/ProjectID/ArchiveID").attrib["accession"]
                xid = int(item.find("Project/ProjectID/ArchiveID").attrib["id"])
                origin = item.find("Project/ProjectID/ArchiveID").attrib["archive"]
                title = item.find("Project/ProjectDescr/Title").text
                try:
                    descr = (
                        item.find("Project/ProjectDescr/Description")
                        .text.strip()
                        .replace("\r", ".")
                        .replace("\n", ".")
                    )
                except AttributeError:
                    descr = None
                try:
                    submission_date = item.find("Submission").attrib["submitted"]
                except KeyError:
                    submission_date = None
                try:
                    owner = item.find('Submission/Description/Organization[@role="owner"]/Name').text
                except AttributeError:
                    owner = None

                results.append(BioProject(xid, name, title, origin, descr, submission_date, owner))
            except Exception:
                try:
                    error = item.find("error").text
                    if error.startswith("The following ID is not public in BioProject:"):
                        xid = error.split(":")[1].strip()
                        log.info("PROJECT %s is not yet public.", xid)
                    else:
                        log.warning("PROJECT failed with error: %s", error)
                        raise
                except Exception:
                    log.warning("PROJECT XML: %s", "".join(xml_to_string(item).split("\n")))
                    raise

        return results
