#!/usr/bin/env python
from pathlib import Path
from shutil import rmtree
import re

results = Path("tests/results/")
rm_dirs = [
    r for r in results.iterdir() if not re.search(r"genomes$", str(r)) and r.is_dir()
]
rm_files = [r for r in results.iterdir() if r.is_file()]

[rmtree(r) for r in rm_dirs]
[r.unlink() for r in rm_files]

genomes = results / "genomes"
if genomes.exists():
    for path in genomes.iterdir():
        if path.is_file():
            path.unlink(missing_ok=True)
