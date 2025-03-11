# pandoomain: the documentation

## Input

### Where/How to get the input?

The accessions could be obtained from NCBI databases.
And the _HMMs_ from _InterPro_ _PFAMs_ or created from an
sequence alignment using _hmmer_.

#### Assembly IDs

Assembly IDs could be gotten from the NCBI Taxonomy DB,
or via using the `datasets` command line NCBI utilily.

For example this is a link to get the assembly IDs of all Bacteria:

+ https://www.ncbi.nlm.nih.gov/datasets/genome/?taxon=2&typical_only=true&exclude_mags=true&exclude_multi_isolates=true

Using the web browser further refinmaent could be done to get exactly the need it IDs.

#### Domains

For example the _HMM_ for the _Pre-toxin TG domain_ with ID _PF14449_ could
be fetched from:

+ https://www.ebi.ac.uk/interpro/wwwapi//entry/pfam/PF14449?annotation=hmm]


## Editing _pandoomain_ parameters

### Parameters on: `config/config.yaml`



### Other parameters


## Output

Example of an output directory tree:

``` txt
results
├── absence_presence.tsv
├── all.faa
├── archs_code.tsv
├── archs_pidrow.tsv
├── archs.tsv
├── genomes
│   ├── GCA_001457635.1
│   │   ├── GCA_001457635.1.faa
│   │   └── GCA_001457635.1.gff
│   ├── GCA_021491795.1
│   │   ├── GCA_021491795.1.faa
│   │   └── GCA_021491795.1.gff
│   ├── GCF_000394295.1
│   │   ├── GCF_000394295.1.faa
│   │   └── GCF_000394295.1.gff
│   ├── GCF_001286845.1
│   │   ├── GCF_001286845.1.faa
│   │   └── GCF_001286845.1.gff
│   ├── genomes.tsv
│   └── not_found.tsv
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

Relationship of rules and their produced files.

![filegraph](../pics/filegraph.svg)

### Files Description

| File | Description | Main Columns |
| ----- | ----------- | ----------- | 
|  genomes_metadata  | NCBI metadata about the assembly. | genome, tax_id |

#### `genome_metadata.tsv`

Metadata of the genome assemblies.
The data is obtained using the datasets NCBI utility.

| genome | org | genus | tax_id | strain | status | level | date | owner | proj | completeness | contamination | cds | method | gc |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| GCF_001286845.1 | Bacillus subtilis | Bacillus | 1423 | NA | current | Contig | 2015-08-31 | EBI | PRJEB9876 | 98.13 | 2.54 | 4061 | NA | 43.5 |
| GCF_001286885.1 | Bacillus subtilis | Bacillus | 1423 | NA | current | Contig | 2015-08-31 | EBI | PRJEB9876 | 97.91 | 2.54 | 3945 | NA | 44 |
| GCF_000394295.1 | Enterococcus faecalis EnGen0248 | Enterococcus | 1158629 | SF19 | current | Scaffold | 2013-05-15 | Broad Institute | PRJNA88885 | 99.5 | 0.05 | 3007 | allpaths v. R41985 | 37 |



#### `genomes_ranks.tsv`

Taxonomic ranks per asssembly.

#### `genomes/genomes.tsv`

Genomes that were downloaded,
and are ready for analysis.

#### `genomes/not_found.tsv`

Genomes that weren't found.

#### `hmmer.tsv`

Table of proteins that
have a hit with the provided domains.

#### `neighbors.tsv`

Table of upstream and downstream
neighbors to the protein hits.
