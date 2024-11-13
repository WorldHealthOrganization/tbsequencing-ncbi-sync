import xml.etree.ElementTree as ET

import pytest

from src.sync_sequencing_data.selectors import get_sra_generic_data

SRA_CONTENT_XML = """<?xml version="1.0" encoding="UTF-8"  ?>\n
                    <EXPERIMENT_PACKAGE_SET>\n
                        <EXPERIMENT_PACKAGE>
                            <EXPERIMENT accession="SRX18158176" alias="QC_2020_nr06_filt_R1">
                                <TITLE>Sequence of Mycobacterium tuberculosis used for EQA.</TITLE>
                            </EXPERIMENT>
                            <Organization type="institute" url="https://www.rivm.nl">
                                <Name>RIVM</Name>
                                <Address postal_code="3721 MA">
                                    <Department>Tuberculosis Reference Laboratory</Department>
                                    <Institution>RIVM</Institution>
                                    <Street>Antonie van Leeuwenhoeklaan 9</Street>
                                    <City>Bilthoven</City>
                                    <Country>Netherlands</Country>
                                </Address>
                                <Contact email="arnout.mulder@rivm.nl">
                                    <Address postal_code="3721 MA">
                                        <Department>Tuberculosis Reference Laboratory</Department>
                                        <Institution>RIVM</Institution>
                                        <Street>Antonie van Leeuwenhoeklaan 9</Street>
                                        <City>Bilthoven</City>
                                        <Country>Netherlands</Country>
                                    </Address>
                                    <Name>
                                        <First>Arnout</First>
                                        <Last>Mulder</Last>
                                    </Name>
                                </Contact>
                            </Organization>
                            <STUDY center_name="BioProject" alias="PRJNA896516" accession="SRP406148">
                                <IDENTIFIERS>
                                    <EXTERNAL_ID namespace="BioProject" label="primary">PRJNA896516</EXTERNAL_ID>
                                </IDENTIFIERS>
                                <DESCRIPTOR>
                                    <STUDY_TITLE>ERLTB-NET MTB EQA</STUDY_TITLE>
                                    <STUDY_TYPE existing_study_type="Other"/>
                                    <STUDY_ABSTRACT>Samples used in the ERLTB-NET MTB EQA coordinated by the RIVM, Bilthoven, The Netherlands</STUDY_ABSTRACT>
                                </DESCRIPTOR>
                            </STUDY>
                            <SAMPLE alias="QC_2020_nr06" accession="SRS15658349">
                                <IDENTIFIERS>
                                    <EXTERNAL_ID namespace="BioSample">SAMN31551447</EXTERNAL_ID>
                                    <SUBMITTER_ID namespace="pda|arnoutmulder@orcid" label="Sample name">QC_2020_nr06</SUBMITTER_ID>
                                </IDENTIFIERS>
                                <SAMPLE_NAME>
                                    <TAXON_ID>1773</TAXON_ID>
                                    <SCIENTIFIC_NAME>Mycobacterium tuberculosis</SCIENTIFIC_NAME>
                                </SAMPLE_NAME>
                                <SAMPLE_LINKS>
                                    <SAMPLE_LINK>
                                        <XREF_LINK>
                                            <DB>bioproject</DB>
                                            <ID>896516</ID>
                                            <LABEL>PRJNA896516</LABEL>
                                        </XREF_LINK>
                                    </SAMPLE_LINK>
                                </SAMPLE_LINKS>
                                <SAMPLE_ATTRIBUTES>
                                    <SAMPLE_ATTRIBUTE>
                                        <TAG>strain</TAG>
                                        <VALUE>QC_2020_nr06</VALUE>
                                    </SAMPLE_ATTRIBUTE>
                                    <SAMPLE_ATTRIBUTE>
                                        <TAG>BioSampleModel</TAG>
                                        <VALUE>Pathogen.cl</VALUE>
                                    </SAMPLE_ATTRIBUTE>
                                </SAMPLE_ATTRIBUTES>
                            </SAMPLE>
                            <Pool>
                                <Member member_name="" accession="SRS15658349" sample_name="QC_2020_nr06" spots="4700162" bases="1337548650" tax_id="1773" organism="Mycobacterium tuberculosis">
                                    <IDENTIFIERS>
                                        <EXTERNAL_ID namespace="BioSample">SAMN31551447</EXTERNAL_ID>
                                    </IDENTIFIERS>
                                </Member>
                            </Pool>
                            <RUN_SET runs="1" bases="1337548650" spots="4700162" bytes="430735965">
                                <RUN accession="SRR22179517" alias="QC_2020_nr06_filt_R1.fastq.gz" total_spots="4700162" total_bases="1337548650" size="430735965" load_done="true" published="2022-11-03 19:06:53" is_public="true" cluster_name="public" has_taxanalysis="1" static_data_available="1">
                                    <IDENTIFIERS>
                                        <SUBMITTER_ID namespace="SUB12237514" label="40">QC_2020_nr06_filt_R1.fastq.gz</SUBMITTER_ID>
                                    </IDENTIFIERS>
                                    <EXPERIMENT_REF accession="SRX18158176">
                                        <IDENTIFIERS>
                                            <SUBMITTER_ID namespace="SUB12237514">QC_2020_nr06_filt_R1</SUBMITTER_ID>
                                        </IDENTIFIERS>
                                    </EXPERIMENT_REF>
                                    <Pool>
                                        <Member member_name="" accession="SRS15658349" sample_name="QC_2020_nr06" spots="4700162" bases="1337548650" tax_id="1773" organism="Mycobacterium tuberculosis">
                                            <IDENTIFIERS>
                                                <EXTERNAL_ID namespace="BioSample">SAMN31551447</EXTERNAL_ID>
                                            </IDENTIFIERS>
                                        </Member>
                                    </Pool>
                                    <SRAFiles>
                                        <SRAFile cluster="public" filename="QC_2020_nr06_filt_R1.fastq.gz" size="311438764" date="2022-11-03 17:00:39" md5="2ce7b801def9c4e0de198b8b680812ca" semantic_name="fastq" supertype="Original" sratoolkit="0">
                                            <Alternatives url="s3://sra-pub-src-13/SRR22179517/QC_2020_nr06_filt_R1.fastq.gz.1" free_egress="-" access_type="Use Cloud Data Delivery" org="AWS"/>
                                            <Alternatives url="gs://sra-pub-src-14/SRR22179517/QC_2020_nr06_filt_R1.fastq.gz.1" free_egress="-" access_type="Use Cloud Data Delivery" org="GCP"/>
                                        </SRAFile>
                                        <SRAFile cluster="public" filename="QC_2020_nr06_filt_R2.fastq.gz" size="312373357" date="2022-11-03 17:00:34" md5="99911dd6aca0aef15a58c67363f0357d" semantic_name="fastq" supertype="Original" sratoolkit="0">
                                            <Alternatives url="s3://sra-pub-src-8/SRR22179517/QC_2020_nr06_filt_R2.fastq.gz.1" free_egress="-" access_type="Use Cloud Data Delivery" org="AWS"/>
                                        </SRAFile>
                                        <SRAFile cluster="public" filename="SRR22179517" url="https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR22179517/SRR22179517" size="430738082" date="2022-11-03 17:00:55" md5="57d4f57bb059005200e6c3cca643ebbc" semantic_name="run" supertype="Primary ETL" sratoolkit="1">
                                            <Alternatives url="s3://sra-pub-hold/sra/SRR22179517/SRR22179517.1" free_egress="-" access_type="Use Cloud Data Delivery" org="AWS"/>
                                            <Alternatives url="https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR22179517/SRR22179517" free_egress="worldwide" access_type="anonymous" org="AWS"/>
                                            <Alternatives url="https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR22179517/SRR22179517" free_egress="worldwide" access_type="anonymous" org="NCBI"/>
                                            <Alternatives url="gs://sra-pub-run-5/SRR22179517/SRR22179517.1" free_egress="gs.US" access_type="gcp identity" org="GCP"/>
                                        </SRAFile>
                                    </SRAFiles>
                                    <CloudFiles>
                                        <CloudFile filetype="fastq" provider="gs" location="gs.US"/>
                                        <CloudFile filetype="fastq" provider="s3" location="s3.us-east-1"/>
                                        <CloudFile filetype="run" provider="gs" location="gs.US"/>
                                        <CloudFile filetype="run" provider="s3" location="s3.us-east-1"/>
                                    </CloudFiles>
                                    <Statistics nreads="2" nspots="4700162">
                                        <Read index="0" count="4700162" average="142.31" stdev="22.26"/>
                                        <Read index="1" count="4700162" average="142.27" stdev="22.29"/>
                                    </Statistics>
                                    <Databases>
                                        <Database>
                                            <Table name="SEQUENCE">
                                                <Statistics source="meta">
                                                    <Rows count="4700162"/>
                                                    <Elements count="1337548650"/>
                                                </Statistics>
                                            </Table>
                                        </Database>
                                    </Databases>
                                    <Bases cs_native="false" count="1337548650">
                                        <Base value="A" count="231188059"/>
                                        <Base value="C" count="435747707"/>
                                        <Base value="G" count="438739187"/>
                                        <Base value="T" count="231857255"/>
                                        <Base value="N" count="16442"/>
                                    </Bases>
                                </RUN>
                            </RUN_SET>
                        </EXPERIMENT_PACKAGE>
                    </EXPERIMENT_PACKAGE_SET>\n
                  """


def test_empty_generic_data():
    variant = (["WGS", "GENOMIC", "RANDOM", "ILLUMINAX", "Illumina HiSeq 2500", "PAIR"], None)
    test_payload = SRA_CONTENT_XML.format(
        strategy=variant[0][0],
        source=variant[0][1],
        selection=variant[0][2],
        platform=variant[0][3],
        machine=variant[0][4],
        library_layout=variant[0][5],
    )
    elements = ET.fromstring(test_payload)
    with pytest.raises(AttributeError):
        get_sra_generic_data(elements[0])


def test_empty_srs():
    test_payload = SRA_CONTENT_XML
    elements = ET.fromstring(test_payload)
    with pytest.raises(AttributeError):
        elements.find("EXPERIMENT/DESIGN/SAMPLE_DESCRIPTOR/IDENTIFIERS/PRIMARY_ID").text
