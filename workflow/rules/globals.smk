from pathlib import Path


def bold_red(msg: str) -> str:
    # error format
    # https://stackoverflow.com/questions/287871/how-do-i-print-colored-text-to-the-terminal
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    return f"{FAIL}{BOLD}{msg}{ENDC}"


def is_internet_on():
    # https://stackoverflow.com/questions/20913411/test-if-an-internet-connection-is-present-in-python
    import socket

    try:
        socket.create_connection(("1.1.1.1", 53))
        return True
    except OSError:
        return False


IN_GENOMES = Path(config.setdefault("genomes", "genomes.txt"))
IN_QUERIES = Path(config.setdefault("queries", "queries"))

RESULTS = Path(config.setdefault("results", "results"))

N_NEIGHBORS = int(config.setdefault("n_neighbors", 12))
BATCH_SIZE = int(config.setdefault("batch_size", 8000))
FAA_WIDTH = int(config.setdefault("faa_width", 80))

ONLY_REFSEQ = bool(config.setdefault("only_refseq", False))
OFFLINE_MODE = bool(config.setdefault("offline", False))


assert IN_GENOMES.is_file(), (
    bold_red("Input genome assembly list file was not found.")
    + f"\nI failed to find it at: {IN_GENOMES.resolve()}"
)

assert IN_QUERIES.is_dir(), (
    bold_red("Input query directory was not found.")
    + f"\nI failed to find it at: {IN_QUERIES.resolve()}"
)

if not OFFLINE_MODE:
    assert is_internet_on(), bold_red("No network connection.")
