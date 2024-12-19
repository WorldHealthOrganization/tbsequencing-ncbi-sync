import xml.etree.ElementTree as ET
from datetime import date

from src.sync_samples.extract_resistance_data import NormalizationData, extract_resistance_data
from src.sync_samples.models import Sample
from src.sync_samples.sql import Drug, Medium, PDSTMethod

BIOSAMPLE_CONTENT_XML = """<?xml version="1.0" ?>
<BioSampleSet>
    <BioSample access="public" publication_date="2022-05-03T00:00:00.000" last_update="2022-05-03T08:11:15.987"
               submission_date="2022-05-03T06:30:07.977" id="28053287" accession="SAMN28053287">
        <Ids>
            <Id db="BioSample" is_primary="1">SAMN28053287</Id>
            <Id db_label="Sample name">Isolate_104</Id>
            <Id db="SRA">SRS12865561</Id>
        </Ids>
        <Description>
            <Title>MDR Mycobacterium tuberculosis isolate from long term infection with a unique genomic deletion:
                second isolate from 2010
            </Title>
            <Organism taxonomy_id="1773" taxonomy_name="Mycobacterium tuberculosis">
                <OrganismName>Mycobacterium tuberculosis</OrganismName>
            </Organism>
            <Comment>
                <Paragraph>MDR Mycobacterium tuberculosis isolate from long term infection with a unique genomic
                    deletion: second isolate from 2010
                </Paragraph>
                <Table class="Antibiogram.mycobacterial.1.0">
                    <Caption>Antibiogram</Caption>
                    <Header>
                        <Cell>Antibiotic</Cell>
                        <Cell>Resistance phenotype</Cell>
                        <Cell>DST Media</Cell>
                        <Cell>DST Method</Cell>
                        <Cell>Critical Concentration</Cell>
                        <Cell>Testing standard</Cell>
                    </Header>
                    <Body>
                        <Row>
                            <Cell>capreomycin</Cell>
                            <Cell>intermediate</Cell>
                            <Cell>solid</Cell>
                            <Cell>Lowenstein-Jensen, resistance ratio</Cell>
                            <Cell>14</Cell>
                            <Cell>CLSI</Cell>
                        </Row>
                        <Row>
                            <Cell>ciprofloxacin</Cell>
                            <Cell>susceptible</Cell>
                            <Cell>solid</Cell>
                            <Cell>Lowenstein-Jensen, resistance ratio</Cell>
                            <Cell>1.6</Cell>
                            <Cell>CLSI</Cell>
                        </Row>
                        <Row>
                            <Cell>clarithromycin</Cell>
                            <Cell>susceptible</Cell>
                            <Cell>solid</Cell>
                            <Cell>Lowenstein-Jensen, resistance ratio</Cell>
                            <Cell>6</Cell>
                            <Cell>CLSI</Cell>
                        </Row>
                        <Row>
                            <Cell>cycloserine</Cell>
                            <Cell>susceptible</Cell>
                            <Cell>solid</Cell>
                            <Cell>Lowenstein-Jensen, resistance ratio</Cell>
                            <Cell>12</Cell>
                            <Cell>CLSI</Cell>
                        </Row>
                        <Row>
                            <Cell>ethambutol</Cell>
                            <Cell>intermediate</Cell>
                            <Cell>solid</Cell>
                            <Cell>Lowenstein-Jensen, resistance ratio</Cell>
                            <Cell>3.2</Cell>
                            <Cell>CLSI</Cell>
                        </Row>
                        <Row>
                            <Cell>ethionamide</Cell>
                            <Cell>intermediate</Cell>
                            <Cell>solid</Cell>
                            <Cell>Lowenstein-Jensen, resistance ratio</Cell>
                            <Cell>20</Cell>
                            <Cell>CLSI</Cell>
                        </Row>
                        <Row>
                            <Cell>isoniazid</Cell>
                            <Cell>resistant</Cell>
                            <Cell>solid</Cell>
                            <Cell>Lowenstein-Jensen, resistance ratio</Cell>
                            <Cell>0.2</Cell>
                            <Cell>CLSI</Cell>
                        </Row>
                        <Row>
                            <Cell>ofloxacin</Cell>
                            <Cell>susceptible</Cell>
                            <Cell>solid</Cell>
                            <Cell>Lowenstein-Jensen, resistance ratio</Cell>
                            <Cell>1.25</Cell>
                            <Cell>CLSI</Cell>
                        </Row>
                        <Row>
                            <Cell>rifampin</Cell>
                            <Cell>resistant</Cell>
                            <Cell>solid</Cell>
                            <Cell>Lowenstein-Jensen, resistance ratio</Cell>
                            <Cell>32</Cell>
                            <Cell>CLSI</Cell>
                        </Row>
                        <Row>
                            <Cell>streptomycin</Cell>
                            <Cell>resistant</Cell>
                            <Cell>solid</Cell>
                            <Cell>Lowenstein-Jensen, resistance ratio</Cell>
                            <Cell>30</Cell>
                            <Cell>CLSI</Cell>
                        </Row>
                    </Body>
                </Table>
            </Comment>
        </Description>
        <Owner>
            <Name>Public Health Laboratory Tel Aviv</Name>
            <Contacts>
                <Contact email="morrub@gmail.com">
                    <Name>
                        <First>Mor</First>
                        <Last>Rubinstein</Last>
                    </Name>
                </Contact>
            </Contacts>
        </Owner>
        <Models>
            <Model>Pathogen.cl</Model>
        </Models>
        <Package display_name="Pathogen: clinical or host-associated; version 1.0">Pathogen.cl.1.0</Package>
        <Attributes>
            <Attribute attribute_name="strain" harmonized_name="strain" display_name="strain">2.2.1 Beijing</Attribute>
            <Attribute attribute_name="collected_by" harmonized_name="collected_by" display_name="collected by">
                missing
            </Attribute>
            <Attribute attribute_name="collection_date" harmonized_name="collection_date"
                       display_name="collection date">2010
            </Attribute>
            <Attribute attribute_name="geo_loc_name" harmonized_name="geo_loc_name" display_name="geographic location">
                Israel
            </Attribute>
            <Attribute attribute_name="host" harmonized_name="host" display_name="host">Homo sapiens</Attribute>
            <Attribute attribute_name="host_disease" harmonized_name="host_disease" display_name="host disease">
                tuberculosis
            </Attribute>
            <Attribute attribute_name="isolation_source" harmonized_name="isolation_source"
                       display_name="isolation source">sputum
            </Attribute>
            <Attribute attribute_name="lat_lon" harmonized_name="lat_lon" display_name="latitude and longitude">32.02 N
                34.9 E
            </Attribute>
            <Attribute attribute_name="host_health_state" harmonized_name="host_health_state"
                       display_name="host health state">active tuberculosis
            </Attribute>
            <Attribute attribute_name="host_sex" harmonized_name="host_sex" display_name="host sex">male</Attribute>
            <Attribute attribute_name="host_tissue_sampled" harmonized_name="host_tissue_sampled"
                       display_name="host tissue sampled">sputum
            </Attribute>
            <Attribute attribute_name="subgroup" harmonized_name="subgroup" display_name="subgroup">2.2.1</Attribute>
            <Attribute attribute_name="subtype" harmonized_name="subtype" display_name="subtype">Beijing</Attribute>
            <Attribute attribute_name="title">MDR Mycobacterium tuberculosis isolate from long term infection with
                strain having a unique genomic deletion: second isolate from 2010
            </Attribute>
        </Attributes>
        <Links>
            <Link type="entrez" target="bioproject" label="PRJNA834625">834625</Link>
        </Links>
        <Status status="live" when="2022-05-03T06:30:07.978"/>
    </BioSample>
</BioSampleSet>"""


def test_basic():
    normalization_data = NormalizationData(
        drugs=[
            Drug(1, ["Isoniazid", "H", "INH"]),
            Drug(2, ["Rifampicin", "R", "RIF"]),
            Drug(3, ["Streptomycin", "S", "STM", "STR"]),
            Drug(4, ["Ethambutol", "E", "EMB"]),
            Drug(5, ["Ofloxacin", "Ofx", "OFL", "OFX"]),
            Drug(6, ["Capreomycin", "Cm", "CAP"]),
            Drug(7, ["Amikacin", "Am", "AMI", "AMK"]),
            Drug(8, ["Kanamycin", "Km", "KAN"]),
            Drug(9, ["Pyrazinamide", "Z", "PZA"]),
            Drug(10, ["Levofloxacin", "Lfx", "LEVO", "LEV", "LVX", "LFX"]),
            Drug(11, ["Moxifloxacin", "Mfx", "MOX", "MOXI", "MXF", "MFX"]),
            Drug(12, ["Para - Aminosalicylic Acid", "Pas", "PAS"]),
            Drug(13, ["Prothionamide", "Pto", "PTO"]),
            Drug(14, ["Cycloserine", "Dcs", "Cs", "DCS", "CYC"]),
            Drug(15, ["Amoxicillin - Clavulanate", "Amx / Clv"]),
            Drug(16, ["Rifabutin", "Mycobutin", "Mb", "RFB"]),
            Drug(17, ["Ethionamide", "Eto", "ETH"]),
            Drug(18, ["Delamanid", "Dld", "DLM"]),
            Drug(19, ["Bedaquiline", "Bdq", "BDQ"]),
            Drug(20, ["Imipenem - Cilastatin", "Ipm / Cln"]),
            Drug(21, ["Linezolid", "Lzd", "LZD"]),
            Drug(22, ["Clofazimine", "Cfz", "CFZ"]),
            Drug(23, ["Clarithromycin", "Clr", "CLR"]),
            Drug(24, ["Fluoroquinolones", "Ft"]),
            Drug(25, ["Aminoglycosides", "AG / CP"]),
            Drug(26, ["Gatifloxacin", "Gfx", "GFX"]),
            Drug(27, ["Ciprofloxacin", "Cip", "CIP"]),
            Drug(28, ["Sitafloxacin", "Sit", "STX", "SIT"]),
            Drug(29, ["Azithromycin", "Azt"]),
        ],
        mediums=[
            Medium(1, "MGIT"),
            Medium(2, "BACTEC460"),
            Medium(3, "LJ"),
            Medium(4, "Agar"),
            Medium(5, "Middlebrook7H9"),
            Medium(6, "Middlebrook7H10"),
            Medium(7, "Middlebrook7H11"),
            Medium(8, "Waynes"),
            Medium(9, "Marks Biphasic"),
            Medium(10, "MODS"),
            Medium(11, "Agar 7H10 Proportion Method"),
            Medium(12, "Agar 7H10 Proportion Method"),
            Medium(13, "Agar 7H10 Proportion Method"),
            Medium(14, "Agar 7H10 Proportion Method"),
            Medium(15, "Agar 7H10 Proportion Method"),
            Medium(16, "Agar 7H10 Proportion Method"),
            Medium(17, "Agar 7H10 Proportion Method"),
            Medium(18, "Agar 7H10 Proportion Method"),
            Medium(19, "Agar 7H10 Proportion Method"),
            Medium(20, "Agar 7H10 Proportion Method"),
            Medium(21, "Agar 7H10 Proportion Method"),
        ],
        methods=[
            PDSTMethod(1, "Resistance Ratio"),
            PDSTMethod(2, "Proportions"),
            PDSTMethod(3, "Direct"),
            PDSTMethod(4, "Nitrate reductase assay"),
        ],
    )

    sample = Sample(
        db_sample_id=1,
        biosample_id=1,
        db_taxon_id=None,
        ncbi_taxon_id=1,
        submission_date=date(2021, 1, 1),
        sampling_date="as",
        latitude=0.1,
        longitude=0.1,
        country_id=1,
        geo_loc_name="dasd",
        isolation_source="str",
        resistance_data=[],
        alias_id=1,
        package_id=2
    )

    elements = ET.fromstring(BIOSAMPLE_CONTENT_XML)
    result = extract_resistance_data(elements[0], sample, normalization_data=normalization_data)
    print(result)
