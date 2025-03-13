<h1 align="center"> <img src="pics/banner.svg" width="2048"> </h1>

<p align="left">
    <a href="https://semver.org/"><img src="https://img.shields.io/badge/version-0.0.1-blue" alt="Semantic Versioning"></a>
   <a href="https://snakemake.github.io/"><img src="https://img.shields.io/badge/snake-make-green" alt="snakemake-green"></a>
    <a href="http://choosealicense.com/licenses/mit/"><img src="https://img.shields.io/badge/license-MIT-red.svg?style=flat" alt="MIT License"></a>
</p>
<hr />

# pandoomain: the pipe

---

## v0.0.1
## Contents

- [Description](#description)
- [Quick Usage](#quick-usage)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Documentation](#documentation)
- [Installation](#installation)

## Description

*pandoomain* is a [*Snakemake pipeline*](https://snakemake.github.io/) designed for:

- Downloading genomes.
- Searching proteins using *Hidden Markov Models* (HMMs).
- Domain annotation via [`interproscan.sh`](https://github.com/ebi-pf-team/interproscan).
- Extracting protein domain architectures.
- Extracting gene neighborhoods.
- Adding taxonomic information.

This pipeline helps identify functional and evolutionary patterns by analyzing *Protein Domain Architecture* and *Gene Neighborhood* data.

Some biological questions are better approached at the domain level rather than at the raw sequence level. This pipeline extends that idea to entire *Gene Neighborhoods*.


### Domain Representation

*pandoomain* encodes a *domain architecture* as a string, offering several advantages:

- Existing libraries for string distance can be directly applied.
- Easier human inspection of raw tables.
- Enables domain alignments.

The encoding method consists of adding *+33*  to each *PFAM ID* and treating the result as a *Unicode code point*.

The reasons for this are:
- Adding *+33* avoids mapping to control and whitespace charaters,
   using the same idea behind the *Phred33 score*.
- *Unicode* can comfortably accommodate all defined *PFAMs* (*\~16,000*), as it provides *155,063* characters.
   User-defined HMMs could be assigned a *code point* bigger than *18,000* to comfortably dodge any *PFAM ID*.

### Pipeline Workflow

The pipeline takes two inputs:

1. A text file with assembly accessions.
2. A directory of *HMMs*.

Then it retrieves genomes (in `.gff` and `.faa` formats), extracts proteins that match any given *HMM*,
annotates them with [`interproscan.sh`](https://github.com/ebi-pf-team/interproscan), and derives *Domain Architectures* at both protein and neighborhood levels.

The final results include taxonomic data for further analysis.

*pandoomain* is used at the [DeMoraes Lab](https://www.demoraeslab.org/) to search for novel bacterial toxins.

### Rulegraph

The steps that conform the pipeline are the following:
![rulegraph](pics/rulegraph.svg)

---

## Quick Usage

### Option 1: Using [`config/config.yaml`](config/config.yaml)

Edit `config/config.yaml` and then run:

```sh
snakemake --cores all
```

### Option 2: Using Command-Line Arguments

Run the pipeline with configuration directly on the command line:

```sh
snakemake --cores all \
          --config \
            genomes=genomes.txt \
            queries=queries
```

*Option 1 is recommended* since an edited configuration file acts as a log of the experiment, improving reproducibility. *Option 2* is useful for quick test runs.

Before running anything perform a test run
adding the following options `-np --printshellcmds`
to the `snakemake` command.

---

## Inputs

1. **Genome List**: A text file with no headers, containing one genome assembly accession per line. Example: [`tests/genomes.txt`](tests/genomes.txt).

   - Use `#` for comments.

2. **HMM Directory**: A directory containing `.hmm` files, which can be obtained from the *InterPro database* or manually generated from alignments.

---

## Outputs

The pipeline generates *TSV tables* summarizing:

- *HMM* hits.
- Genome data.
- Taxonomic information.
- Protein domain architectures.

---

## Documentation

For further details check the documentation at [docs/README.md](docs/README.md).

---


## Installation

### Dependencies

The most complex dependency is *interproscan.sh*, so a helper script is included: [`utils/install_iscan.py`](utils/install_iscan.py).

The pipeline runs through the *Snakemake* framework.

### Cloud Installation

For a guide on cloud deployment, see: [deploy-pandoomain](https://github.com/elbecerrasoto/deploy-pandoomain).

### Local Installation

#### 1. Clone the repository

```sh
git clone 'https://github.com/elbecerrasoto/pandoomain'
cd pandoomain
```

#### 2. Install an Anaconda Distribution

I recommend [Miniforge](https://github.com/conda-forge/miniforge). A *Makefile* rule can simplify this step:

```sh
make install-mamba
```

#### 3. Install the Conda Environment

```sh
~/miniforge3/bin/conda init
source ~/.bashrc
mamba shell init --shell bash --root-prefix=~/miniforge3
source ~/.bashrc
mamba env create --file environment.yml
mamba activate pandoomain
```

#### 4. Install InterProScan

```sh
make install-iscan
```

#### 5. Install R Libraries

```sh
make install-Rlibs
```

#### 6. Test the Installation

```sh
make test
```

---

Everything should now be set up and ready to run. 🚀
