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
                 lambda self, rel_date: [[[21001, 21002], 1, 2], ])

    def efetch(self, db, ids):
        if ids == [21001, 21002]:
            return string_to_xml(generate_experiment_package_set(
                generate_experiment_package(
                    generate_run(
                        generate_sra_file_normalized("a") +
                        generate_sra_file_origin("1") +
                        generate_sra_file_origin("2"),
                        run_accession="ra1"
                    ),
                    sample_accession="sa1",
                    biosample_accession="ba1",
                )
                + generate_experiment_package(
                    generate_run(
                        generate_sra_file_normalized("b") +
                        generate_sra_file_origin("3") +
                        generate_sra_file_origin("4"),
                        run_accession="ra2"
                    ),
                    sample_accession="sa2",
                    biosample_accession="ba2",
                )
            ))
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

    assert len(samples) == 2

    assert len(sample_aliases) == 4
    assert sample_aliases[0][-1] == samples[0][0]
    assert sample_aliases[1][-1] == samples[0][0]
    assert sample_aliases[2][-1] == samples[1][0]
    assert sample_aliases[3][-1] == samples[1][0]

    assert len(sequencingdatas) == 2
    assert sequencingdatas[0][-1] == samples[0][0]
    assert sequencingdatas[1][-1] == samples[1][0]

    assert len(sequencingdatahashes) == 4
    assert sequencingdatahashes[0][-1] == sequencingdatas[0][0]
    assert sequencingdatahashes[1][-1] == sequencingdatas[0][0]
    assert sequencingdatahashes[2][-1] == sequencingdatas[1][0]
    assert sequencingdatahashes[3][-1] == sequencingdatas[1][0]
