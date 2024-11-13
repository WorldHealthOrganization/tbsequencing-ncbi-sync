from typing import Generator

from src.common.logs import create_logger
from src.entrez.base import DB, EFetchResult, EntrezBase
from src.entrez.models import BioProject

log = create_logger(__name__)


class EntrezAdvancedMocked:
    def get_biosample(self, *ids) -> EFetchResult:
        pass

    def get_sra_ids(self, reldate: int) -> Generator[tuple[list[int], int, int], None, None]:
        pass

    def get_biosample_ids(self, reldate: int) -> Generator[tuple[list[int], int, int], None, None]:
        pass

    def get_projects(self, *ids) -> list[BioProject]:
        pass