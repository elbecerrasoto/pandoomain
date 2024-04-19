#!/usr/bin/env python3

from pathlib import Path
from typing import Union
from argparse import ArgumentParser


def run(
    cmd: Union[str, list], dry: bool = False, shell: bool = True, verbose: bool = True
):
    import subprocess as sp

    if verbose:
        is_list = isinstance(cmd, list)
        print(f"Running:\n{' '.join(cmd) if is_list else cmd}")

    if not dry:
        sp.run(cmd, shell=shell, check=True)


def each2str(l: list) -> list:
    return [str(i) for i in l]


parser = ArgumentParser(
    description="Generates test data for the hoox snakemake pipeline."
)

parser.add_argument(
    "--C-grep",
    type=int,
    help="grep context argument -C, used when reducing the gffs.",
    required=True,
)
parser.add_argument("--config", help="config.yaml to pass to snakemake.", required=True)
parser.add_argument(
    "--cache-dir",
    type=Path,
    help="directory to generate the reduced files.",
    required=True,
)
parser.add_argument(
    "--genomes-dir",
    type=Path,
    help="directory where snakemake generates gffs and faas files.",
    required=True,
)

parser.add_argument(
    "--pids",
    nargs="+",
    help="protein IDs, used to reduce gffs, and faas, e.g. WP_072173795.1",
    required=True,
)
parser.add_argument(
    "--genomes",
    nargs="+",
    help="genome list, assembly accessions, e.g. GCF_001286845.1",
    required=True,
)
args = parser.parse_args()

C_GREP = args.C_grep

CONFIG = Path(args.config)
assert CONFIG.exists(), f"{CONFIG} does not exist."

CACHE_DIR = Path(args.cache_dir)
GENOMES_DIR = Path(args.genomes_dir)

PIDs = "|".join(args.pids)
GENOMES = args.genomes


def genomes2ext(ext: str) -> list:
    return [Path(f"{GENOMES_DIR}/{genome}/{genome}{ext}") for genome in GENOMES]


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
            f"grep --perl-regexp -C {C_GREP} '{PIDs}' {GFFs[idx]} > {CACHE_DIR}/{GFFs[idx].name}"
        )


if __name__ == "__main__":
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    download_genomes()
    reduce_genomes()
