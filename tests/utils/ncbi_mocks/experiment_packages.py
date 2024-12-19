# experiment_accession#
from tests.utils.ncbi_mocks.translator import translate


def generate_experiment_package_set(experiment_package: str):
    return translate(XML_EXPERIMENT_PACKAGE_SET, {
        "experiment_package": translate(experiment_package, {
        }),
    })


XML_EXPERIMENT_PACKAGE_SET = """<EXPERIMENT_PACKAGE_SET>\n

    {experiment_package}
</EXPERIMENT_PACKAGE_SET>"""
