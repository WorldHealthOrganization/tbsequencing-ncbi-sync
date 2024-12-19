import xml.etree.ElementTree as ET

from src.sync_samples.selectors import get_biosample_host_name

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
                       display_name="collection date">
            </Attribute>
            <Attribute attribute_name="geo_loc_name" harmonized_name="geo_loc_name" display_name="geographic location">
                France
            </Attribute>
            <Attribute attribute_name="host" harmonized_name="host" display_name="host">{host}</Attribute>
            <Attribute harmonized_name="xyz">
                xyz
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


def test_host_name():
    for variant in [("Homo sapiens", "Homo sapiens"), (None, "")]:
        test_payload = BIOSAMPLE_CONTENT_XML.format(host=variant[0])
        elements = ET.fromstring(test_payload)
        host = get_biosample_host_name(elements[0])
        assert host == variant[1], f"Variant '{variant[0]}' has failed"
