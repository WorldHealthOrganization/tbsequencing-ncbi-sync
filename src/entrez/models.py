from dataclasses import dataclass
from datetime import date
from typing import Optional


@dataclass
class BioProject:
    id: int
    name: str
    title: str

    origin: Optional[str]
    descr: Optional[str]
    submission_date: Optional[str]
    owner: Optional[str]