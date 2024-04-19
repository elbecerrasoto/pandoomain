#!/usr/bin/env python3

from pathlib import Path
from typing import Union
from argparse import ArgumentParser


INCLUDE_DEF = ["genome", "protein", "gff3"]
CWD = Path(os.getcwd())

parser = argparse.ArgumentParser(
    description=DESCRIPTION, formatter_class=argparse.RawDescriptionHelpFormatter
)
parser.add_argument(
    "--C-grep", type=int, help="grep context argument -C, when reducing the gff."
)
parser.add_argument("--config", help="config.yaml to pass to snakemake.")
parser.add_argument(
    "--pids", nargs="+", help="protein IDs used to reduce, separated by '|'."
)
parser.add_argument(
    "--faas", nargs="+", help="faa files, same order as corresponding gff."
)
parser.add_argument(
    "--gffs", nargs="+", help="gff files, same order as corresponding faa."
)

args = parser.parse_args()

C_GREP = args.C_grep
CONFIG = args.config


def run(
    cmd: Union[str, list], dry: bool = False, shell: bool = True, verbose: bool = True
):
    import subprocess as sp

    if verbose:
        is_list = isinstance(cmd, list)
        print(f"Running:\n{' '.join(cmd) if is_list else cmd}")

    if not dry:
        sp.run(cmd, shell=shell, check=True)


def genomes2ext(ext: str) -> list:
    return [Path(f"{GENOMES_DIR}/{genome}/{genome}{ext}") for genome in GENOMES]


def each2str(l: list) -> list:
    return [str(i) for i in l]


GFFs = genomes2ext(".gff")
FAAs = genomes2ext(".faa")


def download_genomes():

    SNAKEMAKE = (
        ["snakemake", "-c", "all", "--configfile", f"{CONFIG}", "--"]
        + each2str(GFFs)
        + each2str(FAAs)
    )

    run(["make", "tests/genomes.txt"], shell=False)
    run(SNAKEMAKE, shell=False)


def reduce_genomes():
    for idx, genome in enumerate(GENOMES):
        run(f"fasta_extract '{PIDs}' < {FAAs[idx]} > {CACHE_DIR}/{FAAs[idx].name}")
        run(
            f"grep --perl-regexp -C {N} '{PIDs}' {GFFs[idx]} > {CACHE_DIR}/{GFFs[idx].name}"
        )


if __name__ == "__main__":
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    download_genomes()
    reduce_genomes()
