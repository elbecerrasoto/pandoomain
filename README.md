<h1 align="center">
<img src="banner.svg" width="2048">
</h1><br>

# pandoomain: the pipe
## 0.0.1
> Summoning dormant, long forgotten proteins ...

## Contents

- [Description](##Description)
- [Quick Usage](##Quick-Usage)
- [INPUTS](##INPUTS)
- [OUTPUTS](##OUTPUTS)
- [Installation](##Installation)

## Description

A [_snakemake pipeline_](https://snakemake.github.io/) capable of:

+ Downloading genomes.
+ Searching proteins using _Hidden Markov Models_ (HMMs).
+ Domain annotation via `interproscan.sh`.
+ Protein domain architecture extraction.
+ Gene-Neighborhood extraction.
+ Adding taxonomic information.

The output data is useful for discovering new functional
or evolutionary patterns through the analysis of
_Protein Domain Architecture_ and _Gene-Neighbohood_ data.

For example some biological questions are better approached
at a Domain level than raw just raw sequence.

This can be taken further with extracting the
domain architecture of whole _Gene-Neighborhoods_.

_pandoomain_ represents a _domain architecture_ as a string.
Which provides the following advantages:
+ Existing libraries for string distance can be easily applied.
+ Makes human inspection of the raw tables easier.
+ Domain aligments are possible.

The conversion strategy is to add `+33` to the _PFAM ID_ (to avoid blank characters),
and treat the resulting number as an _Unicode code point_.

_Unicode_ can easily accomodate all defined _PFAMs_, which are in the order of `~16,000`,
while _Unicode_ provides `155,063` characters.

The input to the pipeline is a text file of
assembly accessions and
and a directory of _HMMs_.

Then the pipelines gets the genomes (in `.gff` and `faa` formates)
and extract any protein that generates a _HMM_ hit.

The resulting _hits_ are then annotated with `interproscan.sh`.

Finally the _Domain Architectures_ (at protein and neighborhood level)
are obtanined.

The final results include taxonomic information for further analysis.

_pandoomain_ is used at the [DeMoraes Lab](https://www.demoraeslab.org/) to search for novel bacterial toxins.

### Rulegraph

![rulegraph](rulegraph.svg)

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

Style 1 is preferred the edited configuration
file act as log of the experiment, and makes
the pipeline reproducible.

Style 2 could be used for test runs.

## INPUTS

1. The input is a text file with no headers
and a genome assembly accession per line.
An example could be found at (tests/genomes.txt)[tests/genomes.txt]

The `#` character could be used for comments.

2. A directory of `.hmm` files. Those could be
obtained from  _interpro database_
or be manually generated from alignments.

## OUTPUTS

_TSV Tables_ summarizing the _HMMs_ hits,
genomes, taxonomy, and domain architectures.

## Usage

### 1. Edit config/config.yaml
### 2. Run snakemake

``` sh
snakemake --cores all --configfile config/config.yaml
```

## Installation

Install the dependencies,
The one that requires the most setup is _interproscan.sh_,
so a helper script is included (utils/install_iscan.py)[utils/install_iscan.py].

Then the pipeline is run through the _snakemake_ framework.

### Cloud Installation

Reading the code at:
+ Check: https://github.com/elbecerrasoto/deploy-hoox

Gives a pretty good walkthorugh of how to install _pandoomain_.

### Local Installation

1. Clone the repository.
``` sh
git clone 'https://github.com/elbecerrasoto/pandoomain'
cd hoox
```

2. Install an _Anaconda Distribution_.

I recommend (Miniforge)[https://github.com/conda-forge/miniforge].
A _Makefile_ rule can by run to facilitate this process.

``` sh
make install-mamba
```

3. Install the _conda_ environment.

``` sh
~/miniforge3/bin/conda init
source ~/.bashrc
mamba shell init --shell bash --root-prefix=~/miniforge3
source ~/.bashrc
mamba env create --file environment.yml
mamba activate hoox
```

4. Install _interproscan.sh_
``` sh
make install-iscan
```


5. Install R libraries.

``` sh
make install-Rlibs
```


5. Test the installation.

``` sh
make test
```