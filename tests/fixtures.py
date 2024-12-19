from typing import Optional

import pytest


class TestConnection:

    conn: Optional[any] = None

    def cursor(self):
        return None

    def commit(self):
        return None

    def close(self):
        return None


@pytest.fixture
def get_sequencingdata_by_hash():
    return None


SRA_CONTENT_XML = """<?xml version="1.0" encoding="UTF-8"  ?>\n
                            <EXPERIMENT_PACKAGE_SET>\n
                                <EXPERIMENT_PACKAGE>
                                    <EXPERIMENT
                                        xmlns="" alias="SID2437" center_name="454MSC" accession="SRX000001">
                                        <IDENTIFIERS>
                                            <PRIMARY_ID>SRX000001</PRIMARY_ID>
                                        </IDENTIFIERS>
                                        <TITLE>454 sequencing of Human HapMap individual NA15510 genomic paired-end library</TITLE>
                                        <STUDY_REF accession="SRP000001">
                                            <IDENTIFIERS>
                                                <PRIMARY_ID>SRP000001</PRIMARY_ID>
                                            </IDENTIFIERS>
                                        </STUDY_REF>
                                        <DESIGN>
                                            <DESIGN_DESCRIPTION>none provided</DESIGN_DESCRIPTION>
                                            <SAMPLE_DESCRIPTOR accession="SRS000605">
                                                <IDENTIFIERS>
                                                    <PRIMARY_ID>SRS000605</PRIMARY_ID>
                                                </IDENTIFIERS>
                                            </SAMPLE_DESCRIPTOR>
                                            <LIBRARY_DESCRIPTOR>
                                                <LIBRARY_NAME>SID2437</LIBRARY_NAME>
                                                <LIBRARY_STRATEGY>WGS</LIBRARY_STRATEGY>
                                                <LIBRARY_SOURCE>GENOMIC</LIBRARY_SOURCE>
                                                <LIBRARY_SELECTION>RANDOM</LIBRARY_SELECTION>
                                                <LIBRARY_LAYOUT>
                                                    <PAIRED NOMINAL_LENGTH="3000"/>
                                                </LIBRARY_LAYOUT>
                                            </LIBRARY_DESCRIPTOR>
                                            <SPOT_DESCRIPTOR>
                                                <SPOT_DECODE_SPEC>
                                                    <READ_SPEC>
                                                        <READ_INDEX>0</READ_INDEX>
                                                        <READ_CLASS>Technical Read</READ_CLASS>
                                                        <READ_TYPE>Adapter</READ_TYPE>
                                                        <BASE_COORD>1</BASE_COORD>
                                                    </READ_SPEC>
                                                </SPOT_DECODE_SPEC>
                                            </SPOT_DESCRIPTOR>
                                        </DESIGN>
                                        <PLATFORM>
                                            <LS454>
                                                <INSTRUMENT_MODEL>454 GS FLX</INSTRUMENT_MODEL>
                                            </LS454>
                                        </PLATFORM>
                                        <PROCESSING/>
                                    </EXPERIMENT>
                                    <SUBMISSION
                                        xmlns=""
                                        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" center_name="454MSC" lab_name="" submission_comment="modified by curator osullivan January 2009" submission_date="2007-06-28T00:01:00Z" alias="SID2437-8,SID2699,SID2735,SID2746-8" accession="SRA000197">
                                        <IDENTIFIERS>
                                            <PRIMARY_ID>SRA000197</PRIMARY_ID>
                                            <SUBMITTER_ID namespace="454MSC">SID2437-8,SID2699,SID2735,SID2746-8</SUBMITTER_ID>
                                        </IDENTIFIERS>
                                    </SUBMISSION>
                                    <Organization type="center">
                                        <Name abbr="454MSC">454 Life Sciences</Name>
                                    </Organization>
                                    <STUDY center_name="454MSC" alias="HUMAN_SV" accession="SRP000001">
                                        <IDENTIFIERS>
                                            <PRIMARY_ID>SRP000001</PRIMARY_ID>
                                            <EXTERNAL_ID namespace="BioProject" label="primary">PRJNA33627</EXTERNAL_ID>
                                            <SUBMITTER_ID namespace="454MSC">HUMAN_SV</SUBMITTER_ID>
                                        </IDENTIFIERS>
                                        <DESCRIPTOR>
                                            <STUDY_TITLE>Paired-end mapping reveals extensive structural variation in the human genome</STUDY_TITLE>
                                            <STUDY_TYPE existing_study_type="Whole Genome Sequencing"/>
                                            <STUDY_ABSTRACT>Structural variation of the genome involves kilobase- to megabase-sized deletions, duplications, insertions, inversions, and complex combinations of rearrangements.</STUDY_ABSTRACT>
                                            <CENTER_PROJECT_NAME>Homo sapiens</CENTER_PROJECT_NAME>
                                        </DESCRIPTOR>
                                        <STUDY_LINKS>
                                            <STUDY_LINK>
                                                <XREF_LINK>
                                                    <DB>pubmed</DB>
                                                    <ID>17901297</ID>
                                                </XREF_LINK>
                                            </STUDY_LINK>
                                        </STUDY_LINKS>
                                    </STUDY>
                                    <SAMPLE center_name="HapMap" alias="NA15510" accession="SRS000605">
                                        <IDENTIFIERS>
                                            <PRIMARY_ID>SRS000605</PRIMARY_ID>
                                            <EXTERNAL_ID namespace="BioSample">SAMN00000376</EXTERNAL_ID>
                                            <EXTERNAL_ID namespace="Coriell">GM15510</EXTERNAL_ID>
                                            <SUBMITTER_ID namespace="HapMap">NA15510</SUBMITTER_ID>
                                        </IDENTIFIERS>
                                        <TITLE>HapMap sample from Homo sapiens</TITLE>
                                        <SAMPLE_NAME>
                                            <TAXON_ID>9606</TAXON_ID>
                                            <SCIENTIFIC_NAME>Homo sapiens</SCIENTIFIC_NAME>
                                        </SAMPLE_NAME>
                                        <DESCRIPTION>Human HapMap individual NA15510</DESCRIPTION>
                                        <SAMPLE_ATTRIBUTES>
                                            <SAMPLE_ATTRIBUTE>
                                                <TAG>population</TAG>
                                                <VALUE>unknown</VALUE>
                                            </SAMPLE_ATTRIBUTE>
                                        </SAMPLE_ATTRIBUTES>
                                    </SAMPLE>
                                    <Pool>
                                        <Member member_name="" accession="SRS000605" sample_name="NA15510" sample_title="HapMap sample from Homo sapiens" spots="3972411" bases="1084760597" tax_id="9606" organism="Homo sapiens">
                                            <IDENTIFIERS>
                                                <PRIMARY_ID>SRS000605</PRIMARY_ID>
                                                <EXTERNAL_ID namespace="BioSample">SAMN00000376</EXTERNAL_ID>
                                                <EXTERNAL_ID namespace="Coriell">GM15510</EXTERNAL_ID>
                                            </IDENTIFIERS>
                                        </Member>
                                    </Pool>
                                    <RUN_SET runs="10" bases="1084760597" spots="3972411" bytes="2659660090">
                                        <RUN alias="EJGTJSJ" run_date="2007-02-01T20:30:00Z" run_center="454MSC" center_name="454MSC" accession="SRR000063" total_spots="172609" total_bases="46700431" size="116420847" load_done="true" published="2008-04-04 15:41:34" is_public="true" cluster_name="public" has_taxanalysis="1" static_data_available="1">
                                            <IDENTIFIERS>
                                                <PRIMARY_ID>SRR000063</PRIMARY_ID>
                                                <SUBMITTER_ID namespace="454MSC">EJGTJSJ</SUBMITTER_ID>
                                            </IDENTIFIERS>
                                            <EXPERIMENT_REF accession="SRX000001" refname="SID2437">
                                                <IDENTIFIERS>
                                                    <PRIMARY_ID>SRX000001</PRIMARY_ID>
                                                    <SUBMITTER_ID namespace="454MSC">SID2437</SUBMITTER_ID>
                                                </IDENTIFIERS>
                                            </EXPERIMENT_REF>
                                            <RUN_ATTRIBUTES>
                                                <RUN_ATTRIBUTE>
                                                    <TAG>flow_count</TAG>
                                                    <VALUE>400</VALUE>
                                                </RUN_ATTRIBUTE>
                                                <RUN_ATTRIBUTE>
                                                    <TAG>key_sequence</TAG>
                                                    <VALUE>TCAG</VALUE>
                                                </RUN_ATTRIBUTE>
                                            </RUN_ATTRIBUTES>
                                            <Pool>
                                                <Member member_name="" accession="SRS000605" sample_name="NA15510" sample_title="HapMap sample from Homo sapiens" spots="172609" bases="46700431" tax_id="9606" organism="Homo sapiens">
                                                    <IDENTIFIERS>
                                                        <PRIMARY_ID>SRS000605</PRIMARY_ID>
                                                        <EXTERNAL_ID namespace="BioSample">SAMN00000376</EXTERNAL_ID>
                                                        <EXTERNAL_ID namespace="Coriell">GM15510</EXTERNAL_ID>
                                                    </IDENTIFIERS>
                                                </Member>
                                            </Pool>
                                            <SRAFiles>
                                                <SRAFile cluster="public" filename="SRR000063" url="https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR000063/SRR000063" size="116424085" date="2012-01-19 15:14:29" md5="e65134591d9bb97b16f86390a04a415f" semantic_name="run" supertype="Primary ETL" sratoolkit="1">
                                                    <Alternatives url="https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR000063/SRR000063" free_egress="worldwide" access_type="anonymous" org="AWS"/>
                                                    <Alternatives url="gs://sra-pub-run-7/SRR000063/SRR000063.3" free_egress="gs.US" access_type="gcp identity" org="GCP"/>
                                                </SRAFile>
                                            </SRAFiles>
                                            <CloudFiles>
                                                <CloudFile filetype="run" provider="gs" location="gs.US"/>
                                            </CloudFiles>
                                            <Statistics nreads="4" nspots="172609">
                                                <Read index="0" count="172609" average="4" stdev="0"/>
                                            </Statistics>
                                            <Bases cs_native="false" count="46700431">
                                                <Base value="A" count="13513617"/>
                                            </Bases>
                                        </RUN>
                                        <RUN alias="EN21GUZ" run_date="2007-04-27T14:08:00Z" run_center="454MSC" center_name="454MSC" accession="SRR000065" total_spots="459023" total_bases="125713591" size="306243423" load_done="true" published="2008-04-04 15:43:35" is_public="true" cluster_name="public" has_taxanalysis="1" static_data_available="1">
                                            <IDENTIFIERS>
                                                <PRIMARY_ID>SRR000065</PRIMARY_ID>
                                                <SUBMITTER_ID namespace="454MSC">EN21GUZ</SUBMITTER_ID>
                                            </IDENTIFIERS>
                                            <EXPERIMENT_REF accession="SRX000001" refname="SID2437">
                                                <IDENTIFIERS>
                                                    <PRIMARY_ID>SRX000001</PRIMARY_ID>
                                                    <SUBMITTER_ID namespace="454MSC">SID2437</SUBMITTER_ID>
                                                </IDENTIFIERS>
                                            </EXPERIMENT_REF>
                                            <RUN_ATTRIBUTES>
                                                <RUN_ATTRIBUTE>
                                                    <TAG>key_sequence</TAG>
                                                    <VALUE>TCAG</VALUE>
                                                </RUN_ATTRIBUTE>
                                            </RUN_ATTRIBUTES>
                                            <Pool>
                                                <Member member_name="" accession="SRS000605" sample_name="NA15510" sample_title="HapMap sample from Homo sapiens" spots="459023" bases="125713591" tax_id="9606" organism="Homo sapiens">
                                                    <IDENTIFIERS>
                                                        <PRIMARY_ID>SRS000605</PRIMARY_ID>
                                                        <EXTERNAL_ID namespace="BioSample">SAMN00000376</EXTERNAL_ID>
                                                        <EXTERNAL_ID namespace="Coriell">GM15510</EXTERNAL_ID>
                                                    </IDENTIFIERS>
                                                </Member>
                                            </Pool>
                                            <SRAFiles>
                                                <SRAFile cluster="public" filename="SRR000065" url="https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR000065/SRR000065" size="306246669" date="2012-01-19 15:14:37" md5="99c0a3256987c93178346f5c1047d91e" semantic_name="run" supertype="Primary ETL" sratoolkit="1">
                                                    <Alternatives url="https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR000065/SRR000065" free_egress="worldwide" access_type="anonymous" org="AWS"/>
                                                    <Alternatives url="gs://sra-pub-run-7/SRR000065/SRR000065.3" free_egress="gs.US" access_type="gcp identity" org="GCP"/>
                                                </SRAFile>
                                            </SRAFiles>
                                            <CloudFiles>
                                                <CloudFile filetype="run" provider="gs" location="gs.US"/>
                                            </CloudFiles>
                                            <Statistics nreads="4" nspots="459023">
                                            </Statistics>
                                            <Bases cs_native="false" count="125713591">
                                                <Base value="A" count="36565560"/>
                                            </Bases>
                                        </RUN>
                                    </RUN_SET>
                                </EXPERIMENT_PACKAGE>
                            </EXPERIMENT_PACKAGE_SET>
                  """
