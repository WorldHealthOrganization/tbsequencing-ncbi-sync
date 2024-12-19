import sys

import pytest

from src.sync_sequencing_data.models import NewSampleAlias
from src.sync_sequencing_data.sql import create_ncbi_package, create_dummy_samples, \
    insert_sample_aliases
from tests.utils.database import TestConnection

def test_single_sample_used_in_multiple_packages():
    db = TestConnection("localhost", "54320", "app", "admin", "password")

    tmp_package_id = create_ncbi_package(db, "A")
    sample_ids = create_dummy_samples(db, tmp_package_id, 1)

    tmp_package_id_2 = create_ncbi_package(db, "B")


    # Inserting the sample alias, the origin
    insert_sample_aliases(db, [NewSampleAlias(
        tmp_package_id=tmp_package_id, sample_id=sample_ids[0],
        name="A",
        alias_type="NCBI", alias_label="",
    )])

    # Inserting the sample alias mapping to the new package singe we are gonna use the same alias here
    # So our expectation is, this alias will be kept linked to the same sample
    # Meaning we will have 2 packages mapped to the same sample by using multiple aliases
    insert_sample_aliases(db, [NewSampleAlias(
        tmp_package_id=tmp_package_id_2, sample_id=sample_ids[0],
        name="A",
        alias_type="NCBI", alias_label="",
    )])


def test_allow_multiple_aliases():
    db = TestConnection("localhost", "54320", "app", "admin", "password")

    tmp_package_id = create_ncbi_package(db, "A")
    sample_ids = create_dummy_samples(db, tmp_package_id, 1)

    tmp_package_id_2 = create_ncbi_package(db, "B")
    sample_ids_2 = create_dummy_samples(db, tmp_package_id_2, 1)

    # Inserting the sample alias, the origin
    insert_sample_aliases(db, [NewSampleAlias(
        tmp_package_id=tmp_package_id, sample_id=sample_ids[0],
        name="A",
        alias_type="NCBI", alias_label="",
    )])

    insert_sample_aliases(db, [NewSampleAlias(
        tmp_package_id=tmp_package_id, sample_id=sample_ids[0],
        name="B",
        alias_type="NCBI", alias_label="",
    )])


def test_disallow_same_alias_being_used_for_different_sample():
    db = TestConnection("localhost", "54320", "app", "admin", "password")

    tmp_package_id = create_ncbi_package(db, "A")
    sample_ids = create_dummy_samples(db, tmp_package_id, 1)

    tmp_package_id_2 = create_ncbi_package(db, "B")
    sample_ids_2 = create_dummy_samples(db, tmp_package_id_2, 1)

    # Inserting the sample alias, the origin
    insert_sample_aliases(db, [NewSampleAlias(
        tmp_package_id=tmp_package_id, sample_id=sample_ids[0],
        name="A",
        alias_type="NCBI", alias_label="",
    )])

    with pytest.raises(Exception):
        insert_sample_aliases(db, [NewSampleAlias(
            tmp_package_id=tmp_package_id_2, sample_id=sample_ids_2[0],
            name="A",
            alias_type="NCBI", alias_label="",
        )])


"""
Here are the values which should be allowed:
1, A
1, B

Here are the values which should not be allowed:
2, X
3, X


Here are the values which should be allowed:
1, A, p1
1, A, p2
"""


"""
Sample ID, Name, Package ID

1, A, 11 - User X
1, A, 12 - User Y
2, A, 13


SampleAlias <-> Package

SampleAlias <-> M2M <-> Package
UNIQUE name


3, UserX_A

3, SRR1231332113, 12
3, SRR1231332113, 24
3, SRR1231332113, 29
4, SRR1231332113, 29

A, UserA_1, 1, UserA
A, UserB_1, 1, UserB

"""



"""

Biosample1, X
Biosample2, X

Sample aliases
Sample ID, Name, Package ID
1       , SRS123213312312, 999
1       , ERS123123123131, 999
1       , ERS123123123131, 1, User A



3   , UserA_ASDASDASDASDASDASDASDASDAS, 1, UserA
4   , UserB_ASDASDASDASDASDASDASDASDAS, 1, UserB

"""