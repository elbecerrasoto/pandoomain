from pathlib import Path

import utils

GENOME_REGEX = r"GC[AF]_\d+\.\d"
CONFIG_FILE = "config/config.yaml"


configfile: CONFIG_FILE


wildcard_constraints:
    genome=GENOME_REGEX,


IN_GENOMES = config.setdefault(Path("genomes.txt"), Path(config["genomes"]))
IN_QUERIES = config.setdefault(Path("queries"), Path(config["queries"]))

RESULTS = Path(config["results"])
RESULTS_GENOMES = RESULTS / "genomes"
USED_GENOMES = RESULTS / "genomes.tsv"
LOGS = RESULTS / "logs"

N_NEIGHBORS = config.setdefault(12, int(config["n_neighbors"]))
BATCH_SIZE = config.setdefault(8000, int(config["batch_size"]))
FAA_WIDTH = config.setdefault(80, int(config["faa_width"]))

ONLY_REFSEQ = config.setdefault("only_refseq", False)
OFFLINE_MODE = config.setdefault("offline", False)


assert IN_GENOMES.is_file(), (
    utils.bold_red("Input genome assembly list file not found.")
    + f"\nTried to look it up at: {IN_GENOMES}."
)

assert IN_QUERIES.is_dir(), (
    utils.bold_red("Input query directory not found.")
    + f"\nTried to look it up at: {IN_QUERIES}."
)

if not OFFLINE_MODE:
    assert utils.is_internet_on(), utils.bold_red("No network connection.")


RESULTS.mkdir(
    parents=True, exist_ok=True
)  # Need it 'cause the output of sort_filter_genomes

GENOMES = utils.sort_filter_genomes(IN_GENOMES, USED_GENOMES, ONLY_REFSEQ)
ALL_FAAS = utils.for_all_genomes(".faa", RESULTS_GENOMES, GENOMES)
