from dataclasses import dataclass
from datetime import date
from typing import Optional

from src.sync_sequencing_data.models import NewSampleAlias


@dataclass
class Drug:
    id: int
    names: list[str]


@dataclass
class Medium:
    id: int
    name: str


@dataclass
class PDSTMethod:
    id: int
    name: str


@dataclass
class ResistanceRecord:
    db_id: Optional[int]
    accession_id: int
    drug: Optional[Drug]
    method: Optional[PDSTMethod]
    medium: Optional[Medium]
    concentration: float
    result: str


@dataclass
class Sample:
    alias_id: int | None
    db_sample_id: int | None
    package_id: int
    biosample_id: int

    db_taxon_id: Optional[int]
    ncbi_taxon_id: int

    submission_date: date
    sampling_date: Optional[str]
    latitude: Optional[str]
    longitude: Optional[str]
    country_id: Optional[str]
    geo_loc_name: Optional[str]
    isolation_source: str
    resistance_data: list[ResistanceRecord]

    additional_aliases: list[NewSampleAlias]


@dataclass
class Taxon:
    id: int
    ncbi_id: int


@dataclass
class NormalizationData:
    drugs: list[Drug]
    mediums: list[Medium]
    methods: list[PDSTMethod]

    def get_drug_by_name(self, name) -> Optional[Drug]:
        for drug in self.drugs:
            if name in drug.names:
                return drug
        return None

    def get_medium_by_name(self, name) -> Optional[Medium]:
        for medium in self.mediums:
            if name == medium.name:
                return medium
        return None

    def get_method_by_name(self, name) -> Optional[PDSTMethod]:
        for method in self.methods:
            if name == method.name:
                return method
        return None
