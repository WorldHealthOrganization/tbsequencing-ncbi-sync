import xml.etree.ElementTree as ET
from datetime import date

from src.sync_samples.extractors import get_collection_date

BIOSAMPLE_CONTENT_XML = """<?xml version="1.0" ?>\n
<BioSampleSet>
    <BioSample access="public" publication_date="2022-10-05T00:50:11.397" last_update="2022-10-05T00:50:11.397"
               submission_date="2021-10-04T10:53:05.247" id="22036263" accession="SAMN22036263">
        <Ids>
            <Id db="BioSample" is_primary="1">SAMN22036263</Id>
            <Id db_label="Sample name">2008025713</Id>
            <Id db="SRA">SRS10436440</Id>
        </Ids>
        <Description>
            <Title>Pathogen: clinical or host-associated sample from Mycobacterium tuberculosis</Title>
            <Organism taxonomy_id="1773" taxonomy_name="Mycobacterium tuberculosis">
                <OrganismName>Mycobacterium tuberculosis</OrganismName>
            </Organism>
        </Description>
        <Owner>
            <Name>Sorbonne Universite, INSERM, U1135</Name>
            <Contacts>
                <Contact email="florence-morel@hotmail.fr">
                    <Name>
                        <First>Florence</First>
                        <Last>MOREL</Last>
                    </Name>
                </Contact>
            </Contacts>
        </Owner>
        <Models>
            <Model>Pathogen.cl</Model>
        </Models>
        <Package display_name="Pathogen: clinical or host-associated; version 1.0">Pathogen.cl.1.0</Package>
        <Attributes>
            <Attribute attribute_name="strain" harmonized_name="strain" display_name="strain">S3</Attribute>
            <Attribute attribute_name="collected_by" harmonized_name="collected_by" display_name="collected by">NRC
                MyRMA
            </Attribute>
            <Attribute attribute_name="collection_date" harmonized_name="collection_date"
                       display_name="collection date">{collection_date}
            </Attribute>
            <Attribute attribute_name="geo_loc_name" harmonized_name="geo_loc_name" display_name="geographic location">
                France
            </Attribute>
            <Attribute attribute_name="host" harmonized_name="host" display_name="host">Homo sapiens</Attribute>
            <Attribute attribute_name="host_disease" harmonized_name="host_disease" display_name="host disease">
                tuberculosis
            </Attribute>
            <Attribute attribute_name="isolation_source" harmonized_name="isolation_source"
                       display_name="isolation source">expectoration S3
            </Attribute>
            <Attribute attribute_name="lat_lon" harmonized_name="lat_lon" display_name="latitude and longitude">
                unknown
            </Attribute>
        </Attributes>
        <Links>
            <Link type="entrez" target="bioproject" label="PRJNA768393">768393</Link>
        </Links>
        <Status status="live" when="2022-10-05T00:50:11.397"/>
    </BioSample>
</BioSampleSet>"""


def test_negative_matchers_produce_none_as_a_result():
    for variant in [
        "" "missing",
        "n/a",
        "na",
        "not collected",
        "unknown",
        "lab strain",
        "not determined",
        "not provided",
        "not present",
        "not applicable",
        "not known",
        "-",
        "none",
        "0+",
        "february 26, 207",
        "not available",
    ]:
        test_payload = BIOSAMPLE_CONTENT_XML.format(collection_date=variant)

        elements = ET.fromstring(test_payload)

        assert get_collection_date(elements[0]) == (None, None), f"Variant '{variant}' has failed"


def test_parses_correct_dates():
    for variant in [
        # keep in mind we add a full year on top!!!
        ("2022", (date(year=2022, month=1, day=1), date(year=2023, month=1, day=1))),
        # keep in mind we add another month on top!!!
        ("2022-03", (date(year=2022, month=3, day=1), date(year=2022, month=4, day=1))),
        ("1123/2123", (date(year=1123, month=1, day=1), date(year=2123, month=1, day=1))),
        ("2456/1456", (date(year=2456, month=1, day=1), date(year=1456, month=1, day=1))),
        # keep in mind we add another month on top!!!
        ("1123-03/2123-02", (date(year=1123, month=3, day=1), date(year=2123, month=3, day=1))),
        ("2456-04/1456-05", (date(year=2456, month=4, day=1), date(year=1456, month=6, day=1))),
        ("1123/2123/2456", (date(year=1123, month=1, day=1), date(year=2457, month=1, day=1))),
        ("2456/1456/1001", (date(year=2456, month=1, day=1), date(year=1002, month=1, day=1))),
        ("1123-03-01", (date(year=1123, month=3, day=1), date(year=1123, month=3, day=2))),
        ("2456-4-1", (date(year=2456, month=4, day=1), date(year=2456, month=4, day=2))),
        ("1123/03/01", (date(year=1123, month=3, day=1), date(year=1123, month=3, day=2))),
        ("2456/4/1", (date(year=2456, month=4, day=1), date(year=2456, month=4, day=2))),
        ("2022-01-02", (date(year=2022, month=1, day=2), date(year=2022, month=1, day=3))),
    ]:
        test_payload = BIOSAMPLE_CONTENT_XML.format(collection_date=variant[0])
        elements = ET.fromstring(test_payload)
        assert get_collection_date(elements[0]) == variant[1], f"Variant '{variant[0]}' has failed"


def test_parses_none_date_attribute():
    date_attr = (
        '<Attribute attribute_name="collection_date" harmonized_name="collection_date"'
        ' display_name="collection date">{collection_date}</Attribute>'
    )
    test_payload = BIOSAMPLE_CONTENT_XML.replace(date_attr, "")
    elements = ET.fromstring(test_payload)
    assert get_collection_date(elements[0]) == (None, None)
