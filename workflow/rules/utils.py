import re
import subprocess as sp
from pathlib import Path

import pandas as pd


def bold_red(msg: str) -> str:
    # error format
    # https://stackoverflow.com/questions/287871/how-do-i-print-colored-text-to-the-terminal
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    # Can't use f"" format strings, cause the formater (snakefmt) introduces spaces
    return FAIL + BOLD + msg + ENDC


def is_internet_on():
    # https://stackoverflow.com/questions/20913411/test-if-an-internet-connection-is-present-in-python
    import socket

    try:
        socket.create_connection(("1.1.1.1", 53))
        return True
    except OSError:
        return False


def sort_filter_genomes(path, filter_regex) -> list:
    # read, trim trailing white space and comments
    df = pd.read_table(path, names=("genome",), sep=r"\s+", comment="#")
    # filter and sort
    genome_matches = [bool(re.match(filter_regex, g)) for g in df.genome]
    df = df.loc[genome_matches, :].sort_values("genome")
    # write
    # df.to_csv(output, header=False, index=False)
    return list(df.genome)


def get_blast_fields(path) -> list[str]:
    df = pd.read_table(
        path,
        sep="\t",
        comment="#",
    )
    return list(df.field)


def for_all_genomes(mark: str, results_genomes: Path, genomes: [str]) -> list[str]:
    return [str(results_genomes / genome / (genome + mark)) for genome in genomes]
