#!/usr/bin/env ipython

import pandas as pd
import re

GENOME_REGEX = r"^GC[AF]_\d+\.\d$"


def remove_comments(x: str) -> str:
    import re
    return re.sub(r"#.*$", "", x).strip()

df = pd.read_table("genomes_messy.txt", names = ("genome",), sep = "\t")
df.genome = df.genome.apply(remove_comments)

genome_matches = [bool(re.match(GENOME_REGEX, g)) for g in df.genome]

df = df.loc[genome_matches, :]

print(df)
