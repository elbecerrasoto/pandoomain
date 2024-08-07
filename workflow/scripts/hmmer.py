#!/usr/bin/env python3
import os
import re
import sys
from pathlib import Path
from typing import Iterable, Union

from pyhmmer import hmmsearch
from pyhmmer.easel import Alphabet, SequenceFile
from pyhmmer.plan7 import HMM, Background, HMMFile

QUERIES_DIR = Path(sys.argv[1])
OUT_FILE = Path(sys.argv[2])
GENOMES = sys.argv[3:]

GENOME_REGEX = re.compile(r"(GCF_\d+\.\d)\.faa$")


class HMMFiles(Iterable[HMM]):
    def __init__(self, *files: Union[str, bytes, os.PathLike]):
        self.files = files

    def __iter__(self):
        for file in self.files:
            with HMMFile(file) as hmm_file:
                yield from hmm_file


alphabet = Alphabet.amino()
background = Background(alphabet)


def get_hmms(queries_path):
    queries_path = Path(queries_path)
    hmms_files = HMMFiles(*queries_path.iterdir())
    return hmms_files


def run_genome(genome_path, hmms_files):
    with SequenceFile(genome_path, digital=True) as genome_file:
        genome = genome_file.read_block()
    hits = hmmsearch(hmms_files, genome)
    return hits


def parse_genome(genome_path):
    genome_path = str(genome_path)
    genome = re.search(GENOME_REGEX, genome_path).group(1)
    return genome


def parse_hit(hit):
    out = [
        (pid := hit.name.decode("utf-8")),
        (query := hit.hits.query_accession.decode("utf-8")),
        (score := hit.score),
        (start := hit.best_domain.env_from),
        (end := hit.best_domain.env_to),
        (included := hit.included),
        (reported := hit.reported),
        (pid_description := hit.description.decode("utf-8")),
        (query_description := hit.hits.query_name.decode("utf-8")),
    ]

    out = [str(i) for i in out]
    return "\t".join(out) + "\n"


if __name__ == "__main__":
    hmms_files = get_hmms(QUERIES_DIR)

    OUT = {}
    for genome in GENOMES:

        genome_id = parse_genome(genome)
        results = run_genome(genome, hmms_files)

        TO_WRITE = list()
        for top_hits in results:
            for hit in top_hits:
                parsed = parse_hit(hit)
                hit_data = f"{genome_id}\t{parsed}"
                TO_WRITE.append(hit_data)

        OUT[genome_id] = TO_WRITE

        del results

    with open(OUT_FILE, "w") as tsv:
        for genome in OUT:
            for hit_data in OUT[genome]:
                tsv.write(hit_data)
