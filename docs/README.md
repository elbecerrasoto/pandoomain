<h1 align="center"> <img src="../pics/banner_docs.svg" width="2048"> </h1>

---

# pandoomain: The Documentation

---

## Input

### Where/How to Obtain Input?

The accession numbers can be obtained from NCBI databases.
HMMs can be sourced from _InterPro_, _PFAM_, or created from a sequence alignment using _HMMER_.

### Assembly IDs

Assembly IDs can be retrieved from the NCBI Taxonomy database
or by using the `datasets` command-line NCBI utility.

For example, this link provides assembly IDs for all Bacteria:

+ [NCBI Genomes](https://www.ncbi.nlm.nih.gov/datasets/genome/?taxon=2&typical_only=true&exclude_mags=true&exclude_multi_isolates=true)

Further refinement can be done via a web browser to obtain the exact required IDs.

#### Example of an Input `genomes.txt` File

```txt
GCF_001286845.1 # my favorite genome
GCA_021491795.1 # this is a comment
GCF_001585665.1 # negative on YwqJ & YwqL proteins
```

### Domains

For example, the _HMM_ for the _Pre-toxin TG domain_ (ID: _PF14449_) can be fetched from:

+ [PF14449](https://www.ebi.ac.uk/interpro/wwwapi//entry/pfam/PF14449?annotation=hmm)

#### Example of an Input `queries` Directory

```txt
queries
├── PF04493_EndoV.hmm
├── PF04740_LXG.hmm
├── PF14431_YwqJ.hmm
└── PF14449_PTTG.hmm
```

##### Example of an HMM File

The first 32 lines of `PF04493_EndoV.hmm`:

```txt
HMMER3/f [3.3 | Nov 2019]
NAME  Endonuclease_5
ACC   PF04493.19
DESC  Endonuclease V
LENG  198
ALPH  amino
RF    no
MM    no
CONS  yes
CS    yes
MAP   yes
DATE  Mon Jan  1 08:39:03 2024
NSEQ  128
EFFN  1.800781
CKSUM 1656237715
GA    23.4 23.4;
TC    23.4 23.5;
NC    23.3 23.3;
BM    hmmbuild HMM.ann SEED.ann
SM    hmmsearch -E 1000 -Z 81514348 --cpu 4 HMM pfamseq
STATS LOCAL MSV      -10.3625  0.70547
STATS LOCAL VITERBI  -11.2035  0.70547
STATS LOCAL FORWARD   -4.9016  0.70547
```

### Configuring _pandoomain_

#### Parameters in: [`config/config.yaml`](config/config.yaml)

#### Other Parameters

The script that downloads the genomes requires the following environmental variable:
+ `NCBI_DATASETS_APIKEY`

If the variable is not set, the script can still download the target genomes, but at a reduced speed.

According to NCBI documentation:

```
E-utils users are allowed 3 requests/second without an API key. Create an API key to increase your e-utils limit to 10 requests/second.
```

To set this up, add the following to your shell configuration:

```sh
export NCBI_DATASETS_APIKEY="your_api_key_here"
```

---

## Output

### Example of an Output Directory Structure

```txt
results
├── absence_presence.tsv
├── all.faa
├── archs_code.tsv
├── archs_pidrow.tsv
├── archs.tsv
├── genomes
│   ├── GCA_001457635.1
│   │   ├── GCA_001457635.1.faa
│   │   └── GCA_001457635.1.gff
│   ├── GCA_021491795.1
│   │   ├── GCA_021491795.1.faa
│   │   └── GCA_021491795.1.gff
│   ├── GCF_000394295.1
│   │   ├── GCF_000394295.1.faa
│   │   └── GCF_000394295.1.gff
│   ├── GCF_001286845.1
│   │   ├── GCF_001286845.1.faa
│   │   └── GCF_001286845.1.gff
│   ├── genomes.tsv
│   └── not_found.tsv
├── genomes_metadata.tsv
├── genomes_ranks.tsv
├── hmmer.tsv
├── iscan.tsv
├── neighbors.tsv
├── taxallnomy_lin_name.tsv
├── taxallnomy.tar.gz
└── TGPD.tsv
```

### Filegraph

Relationships between rules and their output files:

![filegraph](../pics/filegraph.svg)

### Description of Key Output Files

| File | Description | Main Columns |
| ----- | ----------- | ----------- |
| genomes_metadata.tsv | NCBI metadata about the assembly. | genome, tax_id |
| taxallnomy_lin_name.tsv | Data from [taxallnomy](https://sourceforge.net/projects/taxallnomy/). | tax_id, phylum, class, order, family, genus, species |
| genomes_ranks.tsv | Taxa of each assembly. | genome, tax_id |

Intermediary files and less critical ones are marked as hidden files (with a `.` prefix). They are not described as they are subject to change, serving mainly mechanistic roles to keep _pandoomain_ functional.

#### `genomes_metadata.tsv`

Metadata of genome assemblies obtained via the [NCBI datasets utility](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/command-line-tools/download-and-install/).

| genome | org | genus | tax_id | strain | status | level | date | owner | proj | completeness | contamination | cds | method | gc |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| GCF_001286845.1 | Bacillus subtilis | Bacillus | 1423 | NA | current | Contig | 2015-08-31 | EBI | PRJEB9876 | 98.13 | 2.54 | 4061 | NA | 43.5 |
| GCF_000394295.1 | Enterococcus faecalis EnGen0248 | Enterococcus | 1158629 | SF19 | current | Scaffold | 2013-05-15 | Broad Institute | PRJNA88885 | 99.5 | 0.05 | 3007 | allpaths v. R41985 | 37 |

#### `taxallnomy_lin_name.tsv`

Taxonomic data retrieved from [taxallnomy](https://sourceforge.net/projects/taxallnomy/).

#### `genomes_ranks.tsv`

Taxonomic ranks per assembly.

| genome | tax_id | superkingdom | kingdom | phylum | class | order | family | genus | species |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| GCF_004214875.1 | 1193712 | Bacteria | Bacilli | Firmicutes | Bacilli | Bacillales | Bacillaceae | Bacillus | Bacillus subtilis |
| GCF_009268075.1 | 295320 | Bacteria | Bacilli | Firmicutes | Clostridia | Clostridiales | Clostridiaceae | Clostridium | Clostridium difficile |

---

End of documentation.

