#!/usr/bin/env ipython

import re

import pandas as pd

IN = "genomes_messy.txt"
OUT = "genomes.tsv"
ONLY_REFSEQ = False

GENOME_REGEX = r"^GC[AF]_\d+\.\d+$"
REFSEQ_REGEX = r"^GCF_"
ID_REGEX = r"^GC[AF]_(\d+)\.\d+$"
VERSION_REGEX = r"^GC[AF]_\d+\.(\d+)$"


def remove_comments(x: str) -> str:
    return re.sub(r"#.*$", "", x).strip()


df = pd.read_table(IN, names=("genome",), sep="\t")
df.genome = df.genome.apply(remove_comments)

genome_matches = [bool(re.match(GENOME_REGEX, g)) for g in df.genome]

df = df.loc[genome_matches, :]


df["refseq"] = df.genome.apply(lambda x: bool(re.search(REFSEQ_REGEX, x)))
df["id"] = df.genome.apply(lambda x: int(re.search(ID_REGEX, x).group(1)))
df["version"] = df.genome.apply(lambda x: int(re.search(VERSION_REGEX, x).group(1)))

df = df.drop_duplicates()
df = df.sort_values(["id", "version", "refseq"], ascending=False)


if ONLY_REFSEQ:
    df = df[df.refseq]

df = df.groupby("id").first()
df.to_csv(OUT, sep="\t")
