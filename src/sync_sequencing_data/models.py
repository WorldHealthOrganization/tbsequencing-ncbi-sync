from dataclasses import dataclass
from typing import Optional


@dataclass
class SampleAliasMatched:
    sample_id: int
    name: str


@dataclass
class NewSampleAlias:
    tmp_package_id: int
    sample_id: int
    name: str
    alias_type: str
    alias_label: str


@dataclass
class SRARunResultFile:
    db_id: Optional[int]
    db_sample_id: Optional[int]
    db_aliases_created: bool

    file_name: str

    biosample_accession: str
    srs_accession: str

    md5_hashes: list[str]

    library_name: str
    strategy: str
    source: str
    selection: str
    platform: str
    machine: str
    library_layout: str
