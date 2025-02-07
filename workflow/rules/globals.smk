from pathlib import Path

import utils

GENOME_REGEX = r"GC[AF]_\d+\.\d"
CONFIG_FILE = "config/config.yaml"


configfile: CONFIG_FILE


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
LOGS = RESULTS / "logs"

N_NEIGHBORS = int(config["n_neighbors"])
BATCH_SIZE = int(config["batch_size"])
FAA_WIDTH = int(config["faa_width"])

# Optionals keys on config.yaml
ONLY_REFSEQ = config.setdefault("only_refseq", False)

OFFLINE_MODE = config.setdefault("offline", False)
if not OFFLINE_MODE:
    assert utils.is_internet_on(), utils.bold_red("No network connection.")

RESULTS.mkdir(
    parents=True, exist_ok=True
)  # Need it 'cause the output of sort_filter_genomes
GENOMES = utils.sort_filter_genomes(IN_GENOMES, USED_GENOMES, ONLY_REFSEQ)


ALL_FAAS = utils.for_all_genomes(".faa", RESULTS_GENOMES, GENOMES)
