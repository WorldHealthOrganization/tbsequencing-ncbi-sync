import xml.etree.ElementTree as ET
from unittest.mock import patch

from src.sync_sequencing_data.main import main, process_experiment_data
from tests.fixtures import SRA_CONTENT_XML, TestConnection


@patch("src.entrez.entrez.get_content")
@patch("src.entrez.entrez.entrez_get_sra_ids")
@patch("src.entrez.entrez.entrez_configure")
@patch("src.sync_sequencing_data.main.process_experiment_data")
def test_main(experiment_data, entrez_configure, entrez_get_sra_ids, get_content):
    experiment_data.return_value = 10, 20, 30
    entrez_configure.return_value = 123
    biosamples_xml = ET.fromstring(SRA_CONTENT_XML)
    elements = 1
    entrez_get_sra_ids.return_value = iter([25468215])
    get_content.return_value = biosamples_xml, 1
    for experiment_xml in biosamples_xml.findall("EXPERIMENT_PACKAGE"):
        elements = experiment_xml
    db = TestConnection()
    main(db=db, relative_date=1)
    assert experiment_data.call_count == 1
    experiment_data.assert_called_with(db, elements)


@patch("src.sync_sequencing_data.sql.insert_sequencingdata_hash")
@patch("src.sync_sequencing_data.sql.insert_sequencingdata")
@patch("src.sync_sequencing_data.sql.get_sample_id_by_sample_alias")
@patch("src.sync_sequencing_data.sql.get_sequencingdata_by_hash")
def test_process_experiment_data(
    get_sequencingdata_by_hash, get_sample_id_by_sample_alias, insert_sequencingdata, insert_sequencingdata_hash
):
    get_sequencingdata_by_hash.return_value = None
    get_sample_id_by_sample_alias.return_value = 25468215
    insert_sequencingdata.return_value = 3221
    insert_sequencingdata_hash.return_value = None
    md5 = "99c0a3256987c93178346f5c1047d91e"
    biosamples_xml = ET.fromstring(SRA_CONTENT_XML)
    db = TestConnection()
    for experiment_xml in biosamples_xml.findall("EXPERIMENT_PACKAGE"):
        skipped_found, new_samples_added, new_sequencing_files_inserted = process_experiment_data(db, experiment_xml)
        assert skipped_found == 0
        assert new_samples_added == 0
        assert new_sequencing_files_inserted == 2
    assert get_sequencingdata_by_hash.call_count == 2
    get_sequencingdata_by_hash.assert_called_with(None, md5)
    insert_sequencingdata_hash.assert_called_with(None, md5, 3221)
