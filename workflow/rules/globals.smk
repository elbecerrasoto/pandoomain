from pathlib import Path

from snakemake.utils import min_version

import utils

min_version("8.5.3")


configfile: "config/config.yaml"


# Caching used for testing
envvars:
    "SNAKEMAKE_OUTPUT_CACHE",


GENOME_REGEX = r"GC[AF]_\d+\.\d"


wildcard_constraints:
    genome=GENOME_REGEX,


IN_GENOMES = Path(config["genomes"])

assert IN_GENOMES.exists(), (
    utils.bold_red("Input genome assembly list file not found.")
    + f"\nTried to look it up at: {IN_GENOMES}."
)

IN_QUERIES = Path(config["queries"])

assert IN_QUERIES.exists(), (
    utils.bold_red("Input query directory not found.")
    + f"\nTried to look it up at: {IN_QUERIES}."
)

IN_HEADERS = Path("config/headers.yaml")

assert IN_HEADERS.exists(), (
    utils.bold_red("Input blast fields file not found.")
    + f"\nTried to look it up at: {IN_HEADERS}."
)

RESULTS = Path(config["results"])
RESULTS_GENOMES = RESULTS / "genomes"
USED_GENOMES = RESULTS / "genomes.tsv"
LOGS = RESULTS / "logs"

# Optionals keys on YAML
ONLY_REFSEQ = config.setdefault("only_refseq", False)

OFFLINE_MODE = config.setdefault("offline", False)
if not OFFLINE_MODE:
    assert utils.is_internet_on(), utils.bold_red("No network connection.")

RESULTS.mkdir(
    parents=True, exist_ok=True
)  # Need it 'cause the output of sort_filter_genomes
GENOMES = utils.sort_filter_genomes(IN_GENOMES, USED_GENOMES, ONLY_REFSEQ)


HEADERS = utils.read_yaml(IN_HEADERS)

CDS_HEADER_L = HEADERS["CDS_HEADER"]
CDS_HEADER = "\t".join(CDS_HEADER_L)


ISCAN_HEADER_L = HEADERS["ISCAN_HEADER"]
ISCAN_HEADER = "\t".join(ISCAN_HEADER_L)


ALL_CDS = utils.for_all_genomes("_cds.tsv", RESULTS_GENOMES, GENOMES)
ALL_FAAS = utils.for_all_genomes(".faa", RESULTS_GENOMES, GENOMES)
