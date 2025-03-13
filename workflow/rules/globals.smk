from pathlib import Path

import utils

configfile: "config/config.yaml"

IN_GENOMES = Path(config.setdefault("genomes", "genomes.txt"))
IN_QUERIES = Path(config.setdefault("queries", "queries"))

RESULTS = Path(config.setdefault("results", "results"))

N_NEIGHBORS = int(config.setdefault("n_neighbors", 12))
BATCH_SIZE = int(config.setdefault("batch_size", 8000))
FAA_WIDTH = int(config.setdefault("faa_width", 80))

ONLY_REFSEQ = bool(config.setdefault("only_refseq", False))
OFFLINE_MODE = bool(config.setdefault("offline", False))


assert IN_GENOMES.is_file(), (
    utils.bold_red("Input genome assembly list file was not found.")
    + f"\nI failed to find it at: {IN_GENOMES.resolve()}"
)

assert IN_QUERIES.is_dir(), (
    utils.bold_red("Input query directory was not found.")
    + f"\nI failed to find it at: {IN_QUERIES.resolve()}"
)

if not OFFLINE_MODE:
    assert utils.is_internet_on(), utils.bold_red("No network connection.")
