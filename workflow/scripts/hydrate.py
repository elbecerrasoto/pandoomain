#!/usr/bin/env python

import os
import re
import subprocess as sp
import sys
from importlib import import_module
from multiprocessing import Pool
from pathlib import Path
from random import randint
from shutil import rmtree
from time import sleep

import numpy as np
import pandas as pd

sys.path.append(str(Path(os.getcwd()) / "workflow" / "rules"))
utils = import_module("utils")


CPUS = int(sys.argv[1])
OUT_DIR = Path(sys.argv[2])
IN = Path(sys.argv[3])  # A tsv with a header with genome col

COMPRESS = False
GENOMES_REGEX = r"GC[AF]_\d+\.\d"

BATCH_SIZE = 256
MAX_TRIES = 256
CHECK_PROGRESS = 8
OVERWORK = 10

BATCHES_DIR = Path(f"{OUT_DIR}/batches")

NOT_FOUND = Path(f"{OUT_DIR}/not_found.tsv")
NOT_FOUND_TXT = Path(f"{OUT_DIR}/.not_found.txt")
NOT_FOUND_TXT.unlink(missing_ok=True)

GENOMES = Path(f"{OUT_DIR}/genomes.tsv")
GENOMES_TXT = Path(f"{OUT_DIR}/.genomes.txt")
GENOMES_TXT.unlink(missing_ok=True)

KEY = os.environ.setdefault("NCBI_DATASETS_APIKEY", "")

ENCODING = "utf-8"

DEHYDRATE_LEAD = ["datasets", "download", "genome", "accession"]
DEHYDRATE_LAG = ["--dehydrated", "--include", "protein,gff3", "--api-key", f"{KEY}"]
REHYDRATE_LEAD = ["datasets", "rehydrate", "--api-key", f"{KEY}"]


def worker(idx, genomes):
    sleep(0.1 + randint(0, 3))  # Avoids getting blocked by NCBI servers
    unsuccessful_genomes = []

    batch_dir = BATCHES_DIR / str(idx)
    batch_zip = batch_dir / f"{idx}.zip"

    dehydrate_cmd = (
        DEHYDRATE_LEAD + list(genomes) + ["--filename", str(batch_zip)] + DEHYDRATE_LAG
    )
    unzip_cmd = ["unzip", str(batch_zip), "-d", str(batch_dir)]
    rehydrate_cmd = REHYDRATE_LEAD + ["--directory", str(batch_dir)]
    md5sum_cmd = ["md5sum", "-c", "md5sum.txt"]

    try:

        # Batch Processing
        batch_dir.mkdir(parents=True)

        sp.run(dehydrate_cmd, check=True)
        sp.run(unzip_cmd, check=True)
        sp.run(rehydrate_cmd, check=True)
        sp.run(md5sum_cmd, check=True, cwd=batch_dir)

    except (sp.CalledProcessError, FileExistsError) as err:
        print(err)

    for genome in genomes:

        genome_dir = OUT_DIR / str(genome)
        gff = batch_dir / "ncbi_dataset" / "data" / genome / "genomic.gff"
        faa = batch_dir / "ncbi_dataset" / "data" / genome / "protein.faa"

        if gff.is_file() and faa.is_file():
            genome_dir.mkdir(exist_ok=True)
            gff = gff.rename(genome_dir / f"{genome}.gff")
            faa = faa.rename(genome_dir / f"{genome}.faa")

            with open(GENOMES_TXT, "a", encoding=ENCODING) as h:
                h.write(str(genome) + "\n")

            if COMPRESS:
                sp.run(
                    ["pigz", "--processes", str(CPUS), str(gff), str(faa)], check=True
                )
        else:
            unsuccessful_genomes.append(genome)

    return unsuccessful_genomes


def download(genomes: list[str]):

    if len(genomes) == 0:
        return []

    batches = np.array_split(genomes, int(np.ceil(len(genomes) / BATCH_SIZE)))
    batches = tuple(enumerate(batches))

    try:
        rmtree(BATCHES_DIR)
    except FileNotFoundError:
        pass
    BATCHES_DIR.mkdir(parents=True)

    with Pool(CPUS * OVERWORK) as p:
        results = p.starmap(worker, batches)

    rmtree(BATCHES_DIR)

    unsuccessful_genomes = []
    for result in results:
        unsuccessful_genomes.extend(result)

    return unsuccessful_genomes


if __name__ == "__main__":

    # It is more robust if it can
    # read anything line by line
    # and then extract anything that looks like
    # an identifier
    df = pd.read_table(IN)
    genomes = [
        str(g) for g in df.genome if re.search(GENOMES_REGEX, str(g))
    ]  # rm non-matching
    genomes = set(df.genome)  # rm duplications
    genomes = list(df.genome)

    def is_uncomplete(genome):
        genome_dir = OUT_DIR / str(genome)
        if genome_dir.exists():
            gff = genome_dir / f"{genome}.gff"
            faa = genome_dir / f"{genome}.faa"
            complete = gff.exists() and faa.exists()
            if complete:
                with open(GENOMES_TXT, "a", encoding=ENCODING) as h:
                    h.write(str(genome) + "\n")
            return not complete
        else:
            return True

    # rm already downloaded
    genomes = list(filter(is_uncomplete, genomes))

    remaining_genomes = genomes
    for i in range(MAX_TRIES):
        remaining_genomes = download(remaining_genomes)
        if i == 0:
            last = remaining_genomes
        elif (
            not remaining_genomes or remaining_genomes == last
        ) and i % CHECK_PROGRESS == 0:
            break
        last = remaining_genomes

    with open(NOT_FOUND_TXT, "w", encoding=ENCODING) as h:
        for g in remaining_genomes:
            h.write(str(g) + "\n")

    utils.sort_filter_genomes(GENOMES_TXT, GENOMES, only_refseq=False)
    utils.sort_filter_genomes(NOT_FOUND_TXT, NOT_FOUND, only_refseq=False)
