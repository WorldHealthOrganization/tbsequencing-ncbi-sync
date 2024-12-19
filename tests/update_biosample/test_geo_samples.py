# pylint: disable=duplicate-code
import xml.etree.ElementTree as ET

from src.sync_samples.extractors import get_latitude_longitude

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
                       display_name="collection date">2020-01-01
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
            <Attribute attribute_name="lat_lon" harmonized_name="lat_lon" display_name="latitude and longitude">{longitude_latitude}</Attribute>
        </Attributes>
        <Links>
            <Link type="entrez" target="bioproject" label="PRJNA768393">768393</Link>
        </Links>
        <Status status="live" when="2022-10-05T00:50:11.397"/>
    </BioSample>
</BioSampleSet>"""


def test_latitude_logitude():
    for variant in [
        ("23.94546100 S 46.3361585 W", ["23.94546100S", "46.3361585W"]),
        ("23.94546100 N 46.3361585 E", ["23.94546100N", "46.3361585E"]),
        ("not\n                determined\n            ", [None, None]),
        ("not determined", [None, None]),
    ]:

        test_payload = BIOSAMPLE_CONTENT_XML.format(longitude_latitude=variant[0])
        elements = ET.fromstring(test_payload)
        longitude, latitude = get_latitude_longitude(elements[0])
        assert longitude == variant[1][1], f"Variant '{variant[0]}' has failed"
        assert latitude == variant[1][0], f"Variant '{variant[0]}' has failed"


def test_format_for_dbfield():
    from datetime import datetime

    for variant in [
        (
            (datetime.strptime("2021-08-08", "%Y-%m-%d"), datetime.strptime("2021-08-08", "%Y-%m-%d")),
            "[2021-08-08T00:00:00,2021-08-08T00:00:00)",
        ),
        ([None, datetime.strptime("2021-08-08", "%Y-%m-%d")], None),
    ]:
        sampling_date = format_for_dbfield(variant[0][0], variant[0][1])
        assert sampling_date == variant[1], f"Variant '{variant[0]}' has failed"
