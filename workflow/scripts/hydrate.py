#!/usr/bin/env python

import os
import subprocess as sp
import sys
from multiprocessing import Pool
from pathlib import Path
from random import randint
from shutil import rmtree
from time import sleep

import numpy as np
import pandas as pd

CPUS = int(sys.argv[1])
OUT_DIR = Path(sys.argv[2])
IN = Path(sys.argv[3])  # A tsv with a genome col

BATCHES_DIR = Path(f"{OUT_DIR}/batches")
BATCH_SIZE = 256
TRIES = 12

KEY = os.environ.setdefault("NCBI_DATASETS_APIKEY", "")

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

        print(gff)

        if gff.is_file() and faa.is_file():
            genome_dir.mkdir()
            gff = gff.rename(genome_dir / f"{genome}.gff")
            faa = faa.rename(genome_dir / f"{genome}.faa")

            sp.run(["pigz", "--processes", str(CPUS), str(gff), str(faa)], check=True)
        else:
            unsuccessful_genomes.append(genome)

    return unsuccessful_genomes


def download(genomes: list[str]):

    batches = np.array_split(genomes, int(np.ceil(len(genomes) / BATCH_SIZE)))
    batches = tuple(enumerate(batches))

    BATCHES_DIR.mkdir(parents=True)

    with Pool(CPUS) as p:
        results = p.starmap(worker, batches)

    rmtree(BATCHES_DIR)

    unsuccessful_genomes = []
    for result in results:
        unsuccessful_genomes.extend(result)

    return unsuccessful_genomes


if __name__ == "__main__":

    df = pd.read_table(IN)
    genomes = list(df.genome)

    remaining_genomes = genomes
    for i in range(TRIES):
        remaining_genomes = download(remaining_genomes)
        if not remaining_genomes:
            break
