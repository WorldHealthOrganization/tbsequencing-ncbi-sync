# experiment_accession#
from tests.utils.ncbi_mocks.translator import translate


def generate_run(
        sra_files:str,
        run_alias="EQ2FNPT02", run_accession="SRR000066"
):
    return translate(XML_RUN, {
        "sra_files": translate(sra_files, {
            "run_alias": run_alias,
            "run_accession": run_accession,
        }),
        "run_alias": run_alias,
        "run_accession": run_accession,
    })

XML_RUN = """
<RUN alias="{run_alias}" run_date="2007-06-21T14:51:00Z" run_center="WUGSC" center_name="WUGSC"
     accession="{run_accession}" total_spots="242673" total_bases="63790620" size="157437887" load_done="true"
     published="2008-04-04 15:42:42" is_public="true" cluster_name="public" has_taxanalysis="1"
     static_data_available="1">
    <IDENTIFIERS>
        <PRIMARY_ID>{run_accession}</PRIMARY_ID>
        <SUBMITTER_ID namespace="WUGSC">{run_alias}</SUBMITTER_ID>
    </IDENTIFIERS>
    <EXPERIMENT_REF accession="{experiment_accession}" refname="1970218804">
        <IDENTIFIERS>
            <PRIMARY_ID>{experiment_accession}</PRIMARY_ID>
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
            <VALUE>{submission_accession}</VALUE>
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
        <Member member_name="" accession="{sample_accession}" sample_name="19655"
                sample_title="Alistipes putredinis DSM 17216" spots="242673" bases="63790620"
                tax_id="445970" organism="Alistipes putredinis DSM 17216">
            <IDENTIFIERS>
                <PRIMARY_ID>{sample_accession}</PRIMARY_ID>
                <EXTERNAL_ID namespace="BioSample">{biosample_accession}</EXTERNAL_ID>
            </IDENTIFIERS>
        </Member>
    </Pool>
    <SRAFiles>
        {sra_files}
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
</RUN>"""
