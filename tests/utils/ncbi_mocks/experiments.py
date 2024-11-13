from tests.utils.ncbi_mocks.translator import translate


def generate_experiment_package(runs: str, experiment_accession="SRX000008", study_accession="SRP000002",
                                sample_accession="SRS000002",
                                submission_accession="SRA000126", biosample_accession="SAMN00000002"):
    return translate(XML_EXPERIMENT_PACKAGE, {
        "runs": translate(runs, {
            "experiment_accession": experiment_accession,
            "study_accession": study_accession,
            "sample_accession": sample_accession,
            "submission_accession": submission_accession,
            "biosample_accession": biosample_accession,
        }),
        "experiment_accession": experiment_accession,
        "study_accession": study_accession,
        "sample_accession": sample_accession,
        "submission_accession": submission_accession,
        "biosample_accession": biosample_accession,
    })


XML_EXPERIMENT_PACKAGE = """<EXPERIMENT_PACKAGE>
    <EXPERIMENT alias="1970218804" center_name="WUGSC" accession="{experiment_accession}">
        <IDENTIFIERS>
            <PRIMARY_ID>{experiment_accession}</PRIMARY_ID>
        </IDENTIFIERS>
        <TITLE>454 sequencing of Alistipes putredinis DSM 17216 genomic fragment library</TITLE>
        <STUDY_REF accession="{study_accession}" refname="1970209096">
            <IDENTIFIERS>
                <PRIMARY_ID>{study_accession}</PRIMARY_ID>
            </IDENTIFIERS>
        </STUDY_REF>
        <DESIGN>
            <DESIGN_DESCRIPTION>none provided</DESIGN_DESCRIPTION>
            <SAMPLE_DESCRIPTOR accession="{sample_accession}" refname="Alistipes putredinis DSM 17216">
                <IDENTIFIERS>
                    <PRIMARY_ID>{sample_accession}</PRIMARY_ID>
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
                <VALUE>{submission_accession}</VALUE>
            </EXPERIMENT_ATTRIBUTE>
        </EXPERIMENT_ATTRIBUTES>
    </EXPERIMENT>
    <SUBMISSION submission_date="2007-06-23T00:01:00Z"
                submission_comment="Ftp submission of runfiles WUGSC.06232007.070430.79869897.2,WUGSC.06232007.070303.79869897.1 processed manually by shumwaym."
                center_name="WUGSC" lab_name="Genome Sequencing Center" alias="{submission_accession}" accession="{submission_accession}">
        <IDENTIFIERS>
            <PRIMARY_ID>{submission_accession}</PRIMARY_ID>
            <SUBMITTER_ID namespace="WUGSC">{submission_accession}</SUBMITTER_ID>
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
    <STUDY center_name="WUGSC" alias="1970209096" accession="{study_accession}">
        <IDENTIFIERS>
            <PRIMARY_ID>{study_accession}</PRIMARY_ID>
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
    <SAMPLE alias="19655" accession="{sample_accession}">
        <IDENTIFIERS>
            <PRIMARY_ID>{sample_accession}</PRIMARY_ID>
            <EXTERNAL_ID namespace="BioSample">{biosample_accession}</EXTERNAL_ID>
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
        <Member member_name="" accession="{sample_accession}" sample_name="19655"
                sample_title="Alistipes putredinis DSM 17216" spots="498024" bases="130727020" tax_id="445970"
                organism="Alistipes putredinis DSM 17216">
            <IDENTIFIERS>
                <PRIMARY_ID>{sample_accession}</PRIMARY_ID>
                <EXTERNAL_ID namespace="BioSample">{biosample_accession}</EXTERNAL_ID>
            </IDENTIFIERS>
        </Member>
    </Pool>
    <RUN_SET runs="2" bases="130727020" spots="498024" bytes="323257685">
        {runs}
    </RUN_SET>
</EXPERIMENT_PACKAGE>"""
