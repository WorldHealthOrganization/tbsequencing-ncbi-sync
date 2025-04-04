import enum
import math
import os.path
import time
import xml.etree.ElementTree as ET
from http.client import IncompleteRead
from typing import Any, Generator, Iterable, Optional
from urllib.error import HTTPError

from Bio import Entrez

from src.common.logs import create_logger
from src.entrez.caching import Cached

log = create_logger(__name__)

EFetchResult = ET.Element


def xml_to_string(xml) -> str:
    return ET.tostring(xml).decode("utf-8")


def string_to_xml(raw_xml) -> any:
    return ET.fromstring(raw_xml)


def find_text_or_none(xml, *fallback_series: str) -> Optional[str]:
    for selector in fallback_series:
        nodes = xml.findall(selector)
        if len(nodes) > 1:
            raise Exception("More than one node matched")
        if len(nodes) == 1:
            return nodes[0].text
    return None


class DB(enum.Enum):
    BIO_SAMPLE = "biosample"
    SRA = "sra"
    BIO_PROJECT = "bioproject"


class EntrezLow:
    def __init__(self, email: str, api_key: str, enable_caching: bool):
        Entrez.email = email
        Entrez.api_key = api_key

        self.cache = Cached(
            os.path.join(os.path.dirname(__file__), "..", "..", "cached"),
            enable_caching,
        )

    # pylint: disable=too-many-arguments
    def raw_esearch(
        self,
        db: str,
        term: str,
        datetype: str = "pdat",
        retstart: int = 0,
        retmax: int = 10000,
        reldate: Optional[int] = None,
    ):
        log.debug(
            "[ESearch] Low API call db=%s with term=%s page: reldate=%s, retstart=%s, retmax=%s",
            db,
            term,
            reldate,
            retstart,
            retmax,
        )

        payload = dict(
            db=db, term=term, datetype=datetype, retstart=retstart, retmax=retmax
        )

        # optional arguments
        if reldate is not None:
            payload["reldate"] = reldate

        cached = self.cache.get_json(payload)
        if cached:
            log.info("Taking the cached data for %s", db)
            return int(cached["Count"]), cached["IdList"], cached

        attempts = 0
        max_attempts = 10
        while True:
            if attempts >= max_attempts:
                raise Exception("MAX ATTEMPTS REACHED")

            attempts += 1
            try:
                resp = Entrez.read(Entrez.esearch(**payload), validate=True)
                self.cache.set_json(resp, payload)

                return int(resp["Count"]), resp["IdList"], resp
            except HTTPError as e:
                error_message = e.read()
                log.warning(
                    "[ESearch] [Attempt %s] HTTP Error reaching out to the Entrez: %s. Status: %s. Response: %s",
                    attempts,
                    e,
                    e.status,
                    error_message,
                )
                time.sleep(attempts * 5)
            except Exception as e:
                log.warning(
                    "[ESearch] [Attempt %s] Unknown error reaching out to the Entrez: %s",
                    attempts,
                    e,
                )
                time.sleep(attempts * 5)

    def raw_efetch(self, db: str, ids: Iterable[int], retstart=0, retmax=10000):
        log.debug(
            "[EFetch] Low API call db=%s: retstart=%s, retmax=%s, ids=%s",
            db,
            retstart,
            retmax,
            ids,
        )

        attempts = 0
        max_attempts = 10

        cached = self.cache.get(db, ids, retstart, retmax)
        if cached:
            log.info("Taking the cached data for %s", db)
            return ET.fromstring(cached)

        while True:
            if attempts >= max_attempts:
                raise Exception("MAX ATTEMPTS REACHED")

            attempts += 1
            try:
                resp = Entrez.efetch(
                    db=db, id=",".join(map(str, ids)), retstart=retstart, retmax=retmax
                )

                xml, raw = self.raw_efetch_parse(resp)
                self.cache.set(raw, db, ids, retstart, retmax)
                return xml
            except HTTPError as e:
                error_message = e.read()
                log.warning(
                    "[EFetch] [Attempt %s] HTTP Error reaching out to the Entrez: %s. Status: %s. Response: %s",
                    attempts,
                    e,
                    e.status,
                    error_message,
                )
                time.sleep(attempts * 5)
            except Exception as e:
                log.warning(
                    "[EFetch] [Attempt %s] Unknown error reaching out to the Entrez: %s",
                    attempts,
                    e,
                )
                time.sleep(attempts * 5)

    def raw_efetch_parse(self, response: Any) -> tuple[Any, str]:
        log.debug("[EFetch] Parse %s", response)

        attempts = 0
        max_attempts = 10

        while True:
            if attempts >= max_attempts:
                raise Exception("MAX ATTEMPTS REACHED")

            attempts += 1

            raw_xml = None
            try:
                raw_xml = response.read()
                if not raw_xml:
                    raise Exception("Empty response :(")

                return ET.fromstring(raw_xml), raw_xml.decode("utf8")
            except ET.ParseError as e:
                log.warning(
                    "[EFetch] [Attempt %s] Parse error: %s. Content: %s",
                    attempts,
                    e,
                    raw_xml,
                )
                time.sleep(attempts * 10)
            except IncompleteRead as e:
                log.warning("[EFetch] [Attempt %s] Imcomplete read: %s", attempts, e)
                time.sleep(attempts * 60)

    def raw_elink(self, dbfrom: str, dbto: str, ids: list[int], link: str):
        log.debug("[ELink] Low API call dbfrom=%s, dbto=%s: ids=%s", dbfrom, dbto, ids)

        payload = dict(dbfrom=dbfrom, db=dbto, id=ids, linkname=link)

        attempts = 0
        max_attempts = 10
        while True:
            if attempts >= max_attempts:
                raise Exception("MAX ATTEMPTS REACHED")

            attempts += 1
            try:
                resp = Entrez.read(Entrez.elink(**payload), validate=True)
                return resp
            except HTTPError as e:
                error_message = e.read()
                log.warning(
                    "[ESearch] [Attempt %s] HTTP Error reaching out to the Entrez: %s. Status: %s. Response: %s",
                    attempts,
                    e,
                    e.status,
                    error_message,
                )
                time.sleep(attempts * 5)
            except Exception as e:
                log.warning(
                    "[ESearch] [Attempt %s] Unknown error reaching out to the Entrez: %s",
                    attempts,
                    e,
                )
                time.sleep(attempts * 5)


class EntrezBase(EntrezLow):
    DEFAULT_PER_PAGE = 1000

    def esearch(
        self, db: DB, term: str, reldate: Optional[int] = None, datetype: str = "pdat"
    ) -> Generator[tuple[list[int], int, int], None, None]:
        log.info("[ESearch] Call db=%s with term=%s page: reldate=%s", db, term, reldate)

        offset = 0
        total = -1
        page_num = 0

        while offset != total:
            page_num += 1

            total, ids, _ = self.raw_esearch(
                db=str(db.value),
                term=term,
                reldate=reldate,
                retstart=offset,
                retmax=self.DEFAULT_PER_PAGE,
                datetype=datetype,
            )
            offset += len(ids)

            pages_total = math.ceil(total / self.DEFAULT_PER_PAGE)

            log.debug("[ESearch] yield num=%s total=%s", len(ids), total)
            yield ids, page_num, pages_total

    def efetch(self, db: DB, ids: list[int]) -> EFetchResult:
        log.info("[EFetch] Call db=%s, ids=%s", db, ids)

        return self.raw_efetch(db=str(db.value), ids=ids, retstart=0, retmax=len(ids))

    def elink(self, dbfrom: DB, dbto: DB, ids: list[int], link: str) -> list[int]:
        log.info("[ELink] call dbfrom=%s, dbto=%s: ids=%s", dbfrom, dbto, ids)

        data = self.raw_elink(str(dbfrom.value), str(dbto.value), ids, link)

        if data:
            return {
                int(x["IdList"][0]): int(x["LinkSetDb"][0]["Link"][0]["Id"])
                for x in data
                if x["LinkSetDb"] and x["LinkSetDb"][0]["LinkName"] == link
            }
        return {}
