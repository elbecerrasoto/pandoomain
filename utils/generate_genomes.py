#!/usr/bin/env python3

from argparse import ArgumentParser
from pathlib import Path

parser = ArgumentParser(
    description="Link the cached data to the corresponding snakemake results directory."
)

parser.add_argument(
    "--cache-dir",
    type=Path,
    help="directory to generate the reduced files.",
    required=True,
)
parser.add_argument(
    "--link-dir",
    type=Path,
    help="directory to link the cache data.",
    required=True,
)

parser.add_argument(
    "--genomes",
    nargs="+",
    help="genome list, assembly accessions, e.g. GCF_001286845.1",
    required=True,
)

args = parser.parse_args()

CACHE_DIR = Path(args.cache_dir)
LINK_DIR = Path(args.link_dir)

GENOMES = args.genomes


def genomes2ext_targets(ext: str) -> list:
    return [Path(f"{CACHE_DIR}/{genome}{ext}") for genome in GENOMES]


def genomes2ext_links(ext: str) -> list:
    return [Path(f"{LINK_DIR}/{genome}/{genome}{ext}") for genome in GENOMES]


GFFs_targets = genomes2ext_targets(".gff")
FAAs_targets = genomes2ext_targets(".faa")

GFFs_links = genomes2ext_links(".gff")
FAAs_links = genomes2ext_links(".faa")

if __name__ == "__main__":
    for idx, genome in enumerate(GENOMES):

        parent = GFFs_links[idx].parent
        gff = GFFs_links[idx]
        faa = FAAs_links[idx]

        gff_T = GFFs_targets[idx]
        faa_T = FAAs_targets[idx]

        parent.mkdir(parents=True, exist_ok=True)

        gff.unlink(missing_ok=True)
        faa.unlink(missing_ok=True)

        gff.symlink_to(gff_T.resolve())
        faa.symlink_to(faa_T.resolve())
