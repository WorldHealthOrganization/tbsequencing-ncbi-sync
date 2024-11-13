import pytest

from src.entrez.advanced import EntrezAdvanced
from src.entrez.base import string_to_xml
from src.sync_sequencing_data.extract_sra_data import EntrezStructureChangedPossibly
from src.sync_sequencing_data.main import main
from tests.utils.database import Connection
from pytest_mock import MockerFixture


def test_run_file_attributes_changed(mocker: MockerFixture):
    mocker.patch('src.sync_sequencing_data.sql.get_or_create_temporary_ncbi_package', lambda db: 11001)
    mocker.patch('src.entrez.advanced.EntrezAdvanced.get_sra_ids',
                 lambda self, rel_date: [[[21001], 1, 2], [[21002], 2, 2]])
    mocker.patch('src.entrez.advanced.EntrezAdvanced.efetch', lambda self, db, rel_date: string_to_xml(XML_REAL_EXAMPLE))

    conn = Connection("", "", "", "")
    entrez = EntrezAdvanced("-1", "-1", False)

    with pytest.raises(EntrezStructureChangedPossibly) as excinfo:
        main(conn, entrez, 60)
    assert excinfo


XML_REAL_EXAMPLE = """<EXPERIMENT_PACKAGE_SET>\n
    <EXPERIMENT_PACKAGE>
        <EXPERIMENT alias="1970218804" center_name="WUGSC" accession="SRX000008">
            <IDENTIFIERS>
                <PRIMARY_ID>SRX000008</PRIMARY_ID>
            </IDENTIFIERS>
            <TITLE>454 sequencing of Alistipes putredinis DSM 17216 genomic fragment library</TITLE>
            <STUDY_REF accession="SRP000002" refname="1970209096">
                <IDENTIFIERS>
                    <PRIMARY_ID>SRP000002</PRIMARY_ID>
                </IDENTIFIERS>
            </STUDY_REF>
            <DESIGN>
                <DESIGN_DESCRIPTION>none provided</DESIGN_DESCRIPTION>
                <SAMPLE_DESCRIPTOR accession="SRS000002" refname="Alistipes putredinis DSM 17216">
                    <IDENTIFIERS>
                        <PRIMARY_ID>SRS000002</PRIMARY_ID>
                    </IDENTIFIERS>
                </SAMPLE_DESCRIPTOR>
                <LIBRARY_DESCRIPTOR>
                    <LIBRARY_NAME>1970218804</LIBRARY_NAME>
                    <LIBRARY_STRATEGY>WGS</LIBRARY_STRATEGY>
                    <LIBRARY_SOURCE>GENOMIC</LIBRARY_SOURCE>
                    <LIBRARY_SELECTION>RANDOM</LIBRARY_SELECTION>
                    <LIBRARY_LAYOUT>
                        <SINGLE/>
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
                        <READ_SPEC>
                            <READ_INDEX>1</READ_INDEX>
                            <READ_CLASS>Application Read</READ_CLASS>
                            <READ_TYPE>Forward</READ_TYPE>
                            <BASE_COORD>5</BASE_COORD>
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
            <EXPERIMENT_ATTRIBUTES>
                <EXPERIMENT_ATTRIBUTE>
                    <TAG>submission_id</TAG>
                    <VALUE>SRA000126</VALUE>
                </EXPERIMENT_ATTRIBUTE>
            </EXPERIMENT_ATTRIBUTES>
        </EXPERIMENT>
        <SUBMISSION submission_date="2007-06-23T00:01:00Z"
                    submission_comment="Ftp submission of runfiles WUGSC.06232007.070430.79869897.2,WUGSC.06232007.070303.79869897.1 processed manually by shumwaym."
                    center_name="WUGSC" lab_name="Genome Sequencing Center" alias="SRA000126" accession="SRA000126">
            <IDENTIFIERS>
                <PRIMARY_ID>SRA000126</PRIMARY_ID>
                <SUBMITTER_ID namespace="WUGSC">SRA000126</SUBMITTER_ID>
            </IDENTIFIERS>
        </SUBMISSION>
        <Organization type="center">
            <Name abbr="WUGSC">The Genome Center at Washington University School of Medicine in St. Louis</Name>
            <Contact email="lims@genome.wustl.edu" phone="314-286-1115">
                <Name>
                    <First>Lims</First>
                    <Last>Group</Last>
                    <Middle/>
                </Name>
            </Contact>
        </Organization>
        <STUDY center_name="WUGSC" alias="1970209096" accession="SRP000002">
            <IDENTIFIERS>
                <PRIMARY_ID>SRP000002</PRIMARY_ID>
                <EXTERNAL_ID namespace="BioProject" label="primary">PRJNA19655</EXTERNAL_ID>
                <SUBMITTER_ID namespace="WUGSC">1970209096</SUBMITTER_ID>
            </IDENTIFIERS>
            <DESCRIPTOR>
                <STUDY_TITLE>Reference genome for the Human Microbiome Project</STUDY_TITLE>
                <STUDY_TYPE existing_study_type="Whole Genome Sequencing"/>
                <STUDY_ABSTRACT>&lt;P&gt;&lt;B&gt;&lt;I&gt;Alistipes putredinis&lt;/I&gt; DSM 17216.&lt;/B&gt; &lt;I&gt;Alistipes
                    putredinis&lt;/I&gt; DSM 17216 (ATCC 29800) was isolated from human feces. This strain is part of a
                    comprehensive, sequence-based survey of members of the normal human gut microbiota. A joint effort
                    of the WU-GSC and the Center for Genome Sciences at Washington University School of Medicine, the
                    purpose of this survey is to provide the general scientific community with a broad view of the gene
                    content of 100 representatives of the major divisions represented in the intestine\'s microbial
                    community. This information should provide a frame of reference for analyzing metagenomic studies of
                    the human gut microbiome.
                </STUDY_ABSTRACT>
                <CENTER_PROJECT_NAME>Alistipes putredinis DSM 17216</CENTER_PROJECT_NAME>
            </DESCRIPTOR>
            <STUDY_LINKS>
                <STUDY_LINK>
                    <URL_LINK>
                        <LABEL>GOLD</LABEL>
                        <URL>http://genomesonline.org/cgi-bin/GOLD/bin/GOLDCards.cgi?goldstamp=Gi02070</URL>
                    </URL_LINK>
                </STUDY_LINK>
            </STUDY_LINKS>
            <STUDY_ATTRIBUTES>
                <STUDY_ATTRIBUTE>
                    <TAG>parent_bioproject</TAG>
                    <VALUE>PRJNA28331</VALUE>
                </STUDY_ATTRIBUTE>
            </STUDY_ATTRIBUTES>
        </STUDY>
        <SAMPLE alias="19655" accession="SRS000002">
            <IDENTIFIERS>
                <PRIMARY_ID>SRS000002</PRIMARY_ID>
                <EXTERNAL_ID namespace="BioSample">SAMN00000002</EXTERNAL_ID>
                <SUBMITTER_ID namespace="WUGSC" label="Sample name">19655</SUBMITTER_ID>
            </IDENTIFIERS>
            <TITLE>Alistipes putredinis DSM 17216</TITLE>
            <SAMPLE_NAME>
                <TAXON_ID>445970</TAXON_ID>
                <SCIENTIFIC_NAME>Alistipes putredinis DSM 17216</SCIENTIFIC_NAME>
            </SAMPLE_NAME>
            <DESCRIPTION>Alistipes putredinis (GenBank Accession Number for 16S rDNA gene: L16497) is a member of the
                Bacteroidetes division of the domain bacteria and has been isolated from human feces. It has been found
                in 16S rDNA sequence-based enumerations of the colonic microbiota of adult humans (Eckburg et. al.
                (2005), Ley et. al. (2006)).
            </DESCRIPTION>
            <SAMPLE_LINKS>
                <SAMPLE_LINK>
                    <URL_LINK>
                        <LABEL>DNA Source</LABEL>
                        <URL>http://www.dsmz.de/catalogues/details/culture/DSM-17216</URL>
                    </URL_LINK>
                </SAMPLE_LINK>
                <SAMPLE_LINK>
                    <XREF_LINK>
                        <DB>bioproject</DB>
                        <ID>19655</ID>
                    </XREF_LINK>
                </SAMPLE_LINK>
            </SAMPLE_LINKS>
            <SAMPLE_ATTRIBUTES>
                <SAMPLE_ATTRIBUTE>
                    <TAG>finishing strategy (depth of coverage)</TAG>
                    <VALUE>Level 3: Improved-High-Quality Draft11.6x;20</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>collection date</TAG>
                    <VALUE>not determined</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>estimated_size</TAG>
                    <VALUE>2550000</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>sop</TAG>
                    <VALUE>http://hmpdacc.org/doc/CommonGeneAnnotation_SOP.pdf</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>project_type</TAG>
                    <VALUE>Reference Genome</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>host</TAG>
                    <VALUE>Homo sapiens</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>lat_lon</TAG>
                    <VALUE>not determined</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>biome</TAG>
                    <VALUE>terrestrial biome [ENVO:00000446]</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>misc_param: HMP body site</TAG>
                    <VALUE>not determined</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>nucleic acid extraction</TAG>
                    <VALUE>not determined</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>feature</TAG>
                    <VALUE>human-associated habitat [ENVO:00009003]</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>investigation_type</TAG>
                    <VALUE>missing</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>host taxid</TAG>
                    <VALUE>9606</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>project_name</TAG>
                    <VALUE>Alistipes putredinis DSM 17216</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>assembly</TAG>
                    <VALUE>PCAP</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>geo_loc_name</TAG>
                    <VALUE>not determined</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>source_mat_id</TAG>
                    <VALUE>DSM 17216, CCUG 45780, CIP 104286, ATCC 29800, Carlier 10203, VPI 3293</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>material</TAG>
                    <VALUE>biological product [ENVO:02000043]</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>ref_biomaterial</TAG>
                    <VALUE>not determined</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>misc_param: HMP supersite</TAG>
                    <VALUE>gastrointestinal_tract</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>num_replicons</TAG>
                    <VALUE>not determined</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>sequencing method</TAG>
                    <VALUE>454-GS20, Sanger</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>isol_growth_condt</TAG>
                    <VALUE>not determined</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>env_package</TAG>
                    <VALUE>missing</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>strain</TAG>
                    <VALUE>DSM 17216</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>isolation-source</TAG>
                    <VALUE>missing</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>type-material</TAG>
                    <VALUE>type strain of Bacteroides putredinis</VALUE>
                </SAMPLE_ATTRIBUTE>
                <SAMPLE_ATTRIBUTE>
                    <TAG>BioSampleModel</TAG>
                    <VALUE>MIGS.ba</VALUE>
                </SAMPLE_ATTRIBUTE>
            </SAMPLE_ATTRIBUTES>
        </SAMPLE>
        <Pool>
            <Member member_name="" accession="SRS000002" sample_name="19655"
                    sample_title="Alistipes putredinis DSM 17216" spots="498024" bases="130727020" tax_id="445970"
                    organism="Alistipes putredinis DSM 17216">
                <IDENTIFIERS>
                    <PRIMARY_ID>SRS000002</PRIMARY_ID>
                    <EXTERNAL_ID namespace="BioSample">SAMN00000002</EXTERNAL_ID>
                </IDENTIFIERS>
            </Member>
        </Pool>
        <RUN_SET runs="2" bases="130727020" spots="498024" bytes="323257685">
            <RUN alias="EQ2FNPT02" run_date="2007-06-21T14:51:00Z" run_center="WUGSC" center_name="WUGSC"
                 accession="SRR000066" total_spots="242673" total_bases="63790620" size="157437887" load_done="true"
                 published="2008-04-04 15:42:42" is_public="true" cluster_name="public" has_taxanalysis="1"
                 static_data_available="1">
                <IDENTIFIERS>
                    <PRIMARY_ID>SRR000066</PRIMARY_ID>
                    <SUBMITTER_ID namespace="WUGSC">EQ2FNPT02</SUBMITTER_ID>
                </IDENTIFIERS>
                <EXPERIMENT_REF accession="SRX000008" refname="1970218804">
                    <IDENTIFIERS>
                        <PRIMARY_ID>SRX000008</PRIMARY_ID>
                        <SUBMITTER_ID namespace="WUGSC">1970218804</SUBMITTER_ID>
                    </IDENTIFIERS>
                </EXPERIMENT_REF>
                <RUN_ATTRIBUTES>
                    <RUN_ATTRIBUTE>
                        <TAG>flow_count</TAG>
                        <VALUE>400</VALUE>
                    </RUN_ATTRIBUTE>
                    <RUN_ATTRIBUTE>
                        <TAG>submission_id</TAG>
                        <VALUE>SRA000126</VALUE>
                    </RUN_ATTRIBUTE>
                    <RUN_ATTRIBUTE>
                        <TAG>flow_sequence</TAG>
                        <VALUE>
                            TACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACG
                        </VALUE>
                    </RUN_ATTRIBUTE>
                    <RUN_ATTRIBUTE>
                        <TAG>key_sequence</TAG>
                        <VALUE>TCAG</VALUE>
                    </RUN_ATTRIBUTE>
                </RUN_ATTRIBUTES>
                <Pool>
                    <Member member_name="" accession="SRS000002" sample_name="19655"
                            sample_title="Alistipes putredinis DSM 17216" spots="242673" bases="63790620"
                            tax_id="445970" organism="Alistipes putredinis DSM 17216">
                        <IDENTIFIERS>
                            <PRIMARY_ID>SRS000002</PRIMARY_ID>
                            <EXTERNAL_ID namespace="BioSample">SAMN00000002</EXTERNAL_ID>
                        </IDENTIFIERS>
                    </Member>
                </Pool>
                <SRAFiles>
                    <SRAFile cluster="public" filename="SRR000066.lite"
                             url="https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos5/sra-pub-zq-11/SRR000/000/SRR000066/SRR000066.lite.1"
                             size="118588310" date="2022-06-03 14:07:27" md5="044e759c2e430c3db049392b181f6f5a"
                             version="1" semantic_name="SRA Lite" supertype="Primary ETL" sratoolkit="1">
                        <Alternatives
                                url="https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos5/sra-pub-zq-11/SRR000/000/SRR000066/SRR000066.lite.1"
                                free_egress="worldwide" access_type="anonymous" org="NCBI"/>
                        <Alternatives url="gs://sra-pub-zq-9/SRR000066/SRR000066.lite.1" free_egress="gs.US"
                                      access_type="gcp identity" org="GCP"/>
                    </SRAFile>
                    <SRAFile cluster="public" filename="SRR000066"
                             url="https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR000066/SRR000066" size="157440825"
                             date="2012-01-19 15:14:33" md5="4d56c42a5abbad7bc8659265cb2d5eb9" version="3"
                             semantic_name="SRA Normalized v2" supertype="Primary ETL" sratoolkit="1">
                        <Alternatives url="https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR000066/SRR000066"
                                      free_egress="worldwide" access_type="anonymous" org="AWS"/>
                    </SRAFile>
                    <SRAFile cluster="public" filename="EQ2FNPT02.sff" size="398978872" date="2020-06-17 06:51:03"
                             md5="6f5bcfd66a30150dc199e07e57996b11" version="1" semantic_name="sff" supertype="Original"
                             sratoolkit="0">
                        <Alternatives url="s3://sra-pub-src-10/SRR000066/EQ2FNPT02.sff" free_egress="-"
                                      access_type="Use Cloud Data Delivery" org="AWS"/>
                    </SRAFile>
                </SRAFiles>
                <CloudFiles>
                    <CloudFile filetype="run" provider="s3" location="s3.us-east-1"/>
                    <CloudFile filetype="run.zq" provider="gs" location="gs.US"/>
                    <CloudFile filetype="sff" provider="s3" location="s3.us-east-1"/>
                </CloudFiles>
                <Statistics nreads="2" nspots="242673">
                    <Read index="0" count="242673" average="4" stdev="0"/>
                    <Read index="1" count="242673" average="258.87" stdev="27.21"/>
                </Statistics>
                <Bases cs_native="false" count="63790620">
                    <Base value="A" count="15200036"/>
                    <Base value="C" count="16841225"/>
                    <Base value="G" count="17255454"/>
                    <Base value="T" count="14336401"/>
                    <Base value="N" count="157504"/>
                </Bases>
            </RUN>
        </RUN_SET>
    </EXPERIMENT_PACKAGE>
</EXPERIMENT_PACKAGE_SET>"""
