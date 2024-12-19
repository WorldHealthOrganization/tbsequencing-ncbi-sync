import sys

from src.entrez.advanced import EntrezAdvanced
from src.entrez.base import string_to_xml
from src.sync_sequencing_data.main import main
from tests.utils.database import TestConnection
from pytest_mock import MockerFixture

from tests.utils.ncbi_mocks.experiment_packages import generate_experiment_package_set
from tests.utils.ncbi_mocks.experiments import generate_experiment_package
from tests.utils.ncbi_mocks.run import generate_run
from tests.utils.ncbi_mocks.sra_files import generate_sra_file_normalized, generate_sra_file_origin


def test_main(mocker: MockerFixture):
    mocker.patch('src.entrez.advanced.EntrezAdvanced.get_sra_ids',
                 lambda self, rel_date: [[[21001], 1, 2], ])

    def efetch(self, db, ids):
        if ids == [21001]:
            return string_to_xml(generate_experiment_package_set(
                generate_experiment_package(
                    generate_run(
                        generate_sra_file_normalized() +
                        generate_sra_file_origin("1") +
                        generate_sra_file_origin("2")
                    ))))
        raise Exception(f"No mock assigned for {ids}")

    mocker.patch('src.entrez.advanced.EntrezAdvanced.efetch', efetch)

    db = TestConnection("localhost", "54320", "app", "admin", "password")
    entrez = EntrezAdvanced("-1", "-1", False)

    main(db, entrez, 60)
    main(db, entrez, 60)
    main(db, entrez, 60)

    curr = db.cursor()

    curr.execute("SELECT * FROM submission_sample;")
    samples = [row for row in curr.fetchmany(sys.maxsize)]

    curr.execute("SELECT * FROM submission_samplealias;")
    sample_aliases = [row for row in curr.fetchmany(sys.maxsize)]

    curr.execute("SELECT * FROM submission_sequencingdata;")
    sequencingdatas = [row for row in curr.fetchmany(sys.maxsize)]

    curr.execute("SELECT * FROM submission_sequencingdatahash;")
    sequencingdatahashes = [row for row in curr.fetchmany(sys.maxsize)]

    assert len(samples) == 1

    assert len(sample_aliases) == 2
    assert all(alias[-1] == samples[0][0] for alias in sample_aliases)

    assert len(sequencingdatas) == 1
    assert all(seq[-1] == samples[0][0] for seq in sequencingdatas)

    assert len(sequencingdatahashes) == 2
    assert all(hash[-1] == sequencingdatas[0][0] for hash in sequencingdatahashes)
