from tests.utils.ncbi_mocks.translator import translate


def generate_sra_file_normalized(
        md5="6f5bcfd66a30150dc199e07e57996x22"
):
    return XML_NORMALIZED.translate({
        "{md5}": md5,
    })


def generate_sra_file_origin(
        md5="6f5bcfd66a30150dc199e07e57996b12"
):
    return translate(XML_ORIGINAL, {
        "md5": md5,
    })


XML_NORMALIZED = """
<SRAFile cluster="public" filename="{run_accession}.lite"
         url="https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos5/sra-pub-zq-11/SRR000/000/{run_accession}/{run_accession}.lite.1"
         size="118588310" date="2022-06-03 14:07:27" md5="044e759c2e430c3db049392b181f6f5a"
         version="1" semantic_name="SRA Lite" supertype="Primary ETL" sratoolkit="1">
    <Alternatives
            url="https://sra-downloadb.be-md.ncbi.nlm.nih.gov/sos5/sra-pub-zq-11/SRR000/000/{run_accession}/{run_accession}.lite.1"
            free_egress="worldwide" access_type="anonymous" org="NCBI"/>
    <Alternatives url="gs://sra-pub-zq-9/{run_accession}/{run_accession}.lite.1" free_egress="gs.US"
                  access_type="gcp identity" org="GCP"/>
</SRAFile>
<SRAFile cluster="public" filename="{run_accession}"
         url="https://sra-pub-run-odp.s3.amazonaws.com/sra/{run_accession}/{run_accession}" size="157440825"
         date="2012-01-19 15:14:33" md5="{md5}" version="3"
         semantic_name="SRA Normalized" supertype="Primary ETL" sratoolkit="1">
    <Alternatives url="https://sra-pub-run-odp.s3.amazonaws.com/sra/{run_accession}/{run_accession}"
                  free_egress="worldwide" access_type="anonymous" org="AWS"/>
</SRAFile>"""

XML_ORIGINAL = """
<SRAFile cluster="public" filename="{run_alias}.sff" size="398978872" date="2020-06-17 06:51:03"
         md5="{md5}" version="1" semantic_name="sff" supertype="Original"
         sratoolkit="0">
    <Alternatives url="s3://sra-pub-src-10/{run_accession}/{run_alias}.sff" free_egress="-"
                  access_type="Use Cloud Data Delivery" org="AWS"/>
</SRAFile>"""
