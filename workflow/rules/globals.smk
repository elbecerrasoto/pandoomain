from pathlib import Path

from snakemake.utils import min_version

import utils

min_version("8.20.5")


configfile: "config/config.yaml"


# Caching used for testing
# envvars:
#     "SNAKEMAKE_OUTPUT_CACHE",


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


RESULTS = Path(config["results"])
RESULTS_GENOMES = RESULTS / "genomes"
USED_GENOMES = RESULTS / "genomes.tsv"
LOGS = Path(config["results"])

# Optionals keys on config.yaml
ONLY_REFSEQ = config.setdefault("only_refseq", False)

OFFLINE_MODE = config.setdefault("offline", False)
if not OFFLINE_MODE:
    assert utils.is_internet_on(), utils.bold_red("No network connection.")

RESULTS.mkdir(
    parents=True, exist_ok=True
)  # Need it 'cause the output of sort_filter_genomes
GENOMES = utils.sort_filter_genomes(IN_GENOMES, USED_GENOMES, ONLY_REFSEQ)

ISCAN_HEADER = "\t".join(
    [
        "pid",
        "md5",
        "length",
        "analysis",
        "memberDB",
        "memberDB_txt",
        "start",
        "end",
        "score",
        "recommended",
        "date",
        "interpro",
        "interpro_txt",
        "GO",
        "residue",
    ]
)

ALL_FAAS = utils.for_all_genomes(".faa", RESULTS_GENOMES, GENOMES)
