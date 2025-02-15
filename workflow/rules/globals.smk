from pathlib import Path

import utils

GENOME_REGEX = r"GC[AF]_\d+\.\d"


wildcard_constraints:
    genome=GENOME_REGEX,


IN_GENOMES = config.setdefault(Path("genomes.txt"), Path(config["genomes"]))
IN_QUERIES = config.setdefault(Path("queries"), Path(config["queries"]))

RESULTS = Path(config["results"])
RESULTS_GENOMES = RESULTS / "genomes"

N_NEIGHBORS = int(config.setdefault("n_neighbors", 12))
BATCH_SIZE = int(config.setdefault("batch_size", 8000))
FAA_WIDTH = int(config.setdefault("faa_width", 80))

ONLY_REFSEQ = bool(config.setdefault("only_refseq", False))
OFFLINE_MODE = bool(config.setdefault("offline", False))


assert IN_GENOMES.is_file(), (
    utils.bold_red("Input genome assembly list file not found.")
    + f"\nTried to look it up: {IN_GENOMES}"
)

assert IN_QUERIES.is_dir(), (
    utils.bold_red("Input query directory not found.")
    + f"\nTried to look it up: {IN_QUERIES}"
)

if not OFFLINE_MODE:
    assert utils.is_internet_on(), utils.bold_red("No network connection.")
