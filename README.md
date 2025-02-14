
# HOOX

**v0.0.1**

## Description

A [_snakemake pipeline_](https://snakemake.github.io/)
to search for HMMs hits on database of bacterial genomes.

As additional features, the gene neighborhoods of
any hit would be extracted and taxonomic information
would be obtained.

The input to the pipeline is a text file providing the
assembly accessions of the target genomes
and a directory of the HMMs to be search.

The accessions could be obtained from NCBI databases.
And the HMMs from _interpro_ PFAMs or manually created
with _hmmer_.

## Quick Usage

###  Style 1: using config/config.yaml

Edit config/config.yaml and then run.
``` sh
snakemake --cores all
```

### Style 2: command line arguments

Specify configuration directly on the command line.
``` sh
snakemake --cores all\
          --config\
            genomes=genomes.txt\
            queries=queries
```

Style 1 is preferred as is the edited configuration
file act as log of the experiment, and makes
the pipeline reproducible.

Style 2 could be used for test runs.

## Inputs
1. The input is a text file with no headers
and a genome assembly accession per line.
An example could be found at _tests/genomes.txt_.

The `#` character could be used for comments.

2. A directory of `.hmm` files. Those could be
obtained from  _intepro database_
or be manually generated from alignments.


## Outputs

_TSV Tables_ summarizing the HMMs hits,
genome taxonomy and hits gene neighborhoods.

## Dependencies

### snakemake

I recommend installing _snakemake_ through
an _Anaconda Distribution._

My favorite one is [_miniforge_](https://github.com/conda-forge/miniforge).

This _README_ uses _mamba_, but substitute by _conda_ if appropriately.

### interproscan.sh

An installer script is provided.

### ncbi-datasets cli

### Linux utilities

+ pigz
+ gnu-make
+ aria2c

### R

+ tidyverse
+ seqinr
+ segmenTools
+ data.table

### python

+ pyhmmer
+ biopython
+ pandas

## Installation

1. Clone the repository.
``` sh
git clone 'https://github.com/elbecerrasoto/hoox'
cd hoox
```

2. Install the software through an _Anaconda Distribution_.
``` sh
mamba env create
mamba activate variants
```

3. Install _interproscan.sh_.
``` sh
make install-iscan
```

Test the installation.
``` sh
make test
```

## Usage

The pipeline uses the snakemake conventions,
so you can edit the config file at `config/config.yaml`,
and then run:

+ `snakemake --cores all --use-conda`
