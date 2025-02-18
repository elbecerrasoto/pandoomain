#!/usr/bin/env python
from pathlib import Path
from shutil import rmtree
import re

RESULTS = Path("tests/results/")


if RESULTS.is_dir():
    rm_dirs = [
        r
        for r in RESULTS.iterdir()
        if not re.search(r"genomes$", str(r)) and r.is_dir()
    ]
    rm_files = [r for r in RESULTS.iterdir() if r.is_file()]
    # Actual work
    [rmtree(r) for r in rm_dirs]
    [r.unlink() for r in rm_files]

GENOMES = RESULTS / "genomes"
if GENOMES.exists():
    for path in GENOMES.iterdir():
        if path.is_file():
            path.unlink(missing_ok=True)
