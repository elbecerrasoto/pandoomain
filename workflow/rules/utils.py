import re
from pathlib import Path

import pandas as pd


def read_yaml(y: Path) -> dict:
    import yaml

    with open(y, "r") as yfile:
        return yaml.safe_load(yfile)


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


def sort_filter_genomes(inpath: Path, outpath: Path, only_refseq: bool) -> list[str]:
    """
    Given a input genome list (genome assembly accessions).
    Generate a python list with valid ids.
    The list is the input to the Snakemake hoox pipeline.

     A tsv with the used ids is generated on a given location.
    """

    GENOME_REGEX = r"^GC[AF]_\d+\.\d+$"
    REFSEQ_REGEX = r"^GCF_"
    ID_REGEX = r"^GC[AF]_(\d+)\.\d+$"
    VERSION_REGEX = r"^GC[AF]_\d+\.(\d+)$"

    def remove_comments(x: str) -> str:
        return re.sub(r"#.*$", "", x).strip()

    df = pd.read_table(inpath, names=("genome",), sep="\t")
    df.genome = df.genome.apply(remove_comments)

    genome_matches = [bool(re.match(GENOME_REGEX, g)) for g in df.genome]

    df = df.loc[genome_matches, :]

    df["refseq"] = df.genome.apply(lambda x: bool(re.search(REFSEQ_REGEX, x)))
    df["id"] = df.genome.apply(lambda x: int(re.search(ID_REGEX, x).group(1)))
    df["version"] = df.genome.apply(lambda x: int(re.search(VERSION_REGEX, x).group(1)))

    df = df.drop_duplicates()
    df = df.sort_values(["id", "version", "refseq"], ascending=False)

    if only_refseq:
        df = df[df.refseq]

    df = df.groupby("id").first()
    df.to_csv(outpath, sep="\t")

    return list(df.genome)


def get_blast_fields(path) -> list[str]:
    df = pd.read_table(
        path,
        sep="\t",
        comment="#",
    )
    return list(df.field)


def for_all_genomes(mark: str, results_genomes: Path, genomes: [str]) -> list[str]:
    return [str(results_genomes / genome / f"{genome}{mark}") for genome in genomes]
