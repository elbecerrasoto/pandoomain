<h1 align="center"> <img src="../pics/banner_docs.svg" width="2048"> </h1>

---

# Pandoomain Documentation

---

## Contents

- [Input](#input)
  - [Assembly IDs](#assembly-ids)
  - [Domains](#domains)
  - [Configuration](#configuration)
- [Output](#output)
  - [Example Output Directory Structure](#example-output-directory-structure)
  - [Filegraph](#filegraph)
  - [Key Output Files](#key-output-files)

## Input

> **Where to Obtain Input Data?**

- Assembly accession numbers can be retrieved from NCBI databases.
- HMM profiles can be obtained from _InterPro_, _PFAM_, or generated via _HMMER_ from sequence alignments.

### Assembly IDs

Assembly IDs can be sourced from the NCBI Taxonomy database or using the [`datasets` command-line tool](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/command-line-tools/download-and-install/).

Example link for bacterial assembly IDs:

- [NCBI Genomes](https://www.ncbi.nlm.nih.gov/datasets/genome/?taxon=2&typical_only=true&exclude_mags=true&exclude_multi_isolates=true)

#### Example `genomes.txt` Input File

```txt
GCF_001286845.1 # my favorite genome
GCA_021491795.1 # this is a comment
GCF_001585665.1 # negative on YwqJ & YwqL proteins
```

### Domains

HMM profiles for domains can be fetched from sources like PFAM. Example:

- [_Pre-toxin TG domain_ (PF14449)](https://www.ebi.ac.uk/interpro/wwwapi//entry/pfam/PF14449?annotation=hmm)

#### Example `queries` Directory Structure

```txt
queries
├── PF04493_EndoV.hmm
├── PF04740_LXG.hmm
├── PF14431_YwqJ.hmm
└── PF14449_PTTG.hmm
```

#### Example HMM File

Test HMM profiles are available in [`tests/queries`](../tests/queries), e.g.:

- [`PF04493_EndoV.hmm`](../tests/queries/PF04493_EndoV.hmm)

### Configuration

#### [`config/config.yaml`](../config/config.yaml)

Pipeline configuration is managed via [`config/config.yaml`](../config/config.yaml). The key option is:

- **`n_neighbors`**: Specifies the number of neighboring genes to return (±N positions relative to the hit). If a hit is near a contig boundary, fewer than `2N` genes may be returned.

#### Example `config.yaml`

```yaml
# Input genome list.
genomes:
  genomes.txt

# Directory of .hmm profiles.
queries:
  queries

# Output directory.
results:
  results

# Number of neighboring genes.
n_neighbors:
  12

# Batch size for InterPro runs.
batch_size:
  8000

# FASTA formatting width.
faa_width:
  80

# Use only RefSeq genomes.
only_refseq:
  false

# Allow offline mode without error.
offline:
  false
```

#### Environmental Variables

The genome download script requires:

- `NCBI_DATASETS_APIKEY` (increases request limit from 3 to 10/sec per NCBI guidelines).

To set it up, add to your shell config (e.g., `~/.bashrc`):

```sh
export NCBI_DATASETS_APIKEY="your_api_key_here"
```

If not provided the 3 requests per second limit is used.

---

## Output

### Example Output Directory Structure

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
│   ├── genomes.tsv
│   └── not_found.tsv
├── genomes_metadata.tsv
├── hmmer.tsv
├── neighbors.tsv
├── taxallnomy_lin_name.tsv
└── TGPD.tsv
```

### Filegraph

Illustrating rule-output file relationships:

![filegraph](../pics/filegraph.svg)

### Key Output Files

| File | Description | Key Columns |
|------|-------------|-------------|
| `genomes_metadata.tsv` | NCBI assembly metadata. | genome, tax_id |
| `taxallnomy_lin_name.tsv` | Taxonomic lineage info. | tax_id, kingdom, phylum, class, order, family, genus, species|
| `genomes_ranks.tsv` | Taxonomic ranks per assembly. | genome, tax_id |
| `genomes/genomes.tsv` | Successfully downloaded genomes. | genome |
| `genomes/not_found.tsv` | Failed genome downloads. | genome |
| `hmmer.tsv` | Query HMM hits. | genome, pid, query |
| `neighbors.tsv` | Gene neighborhoods of hits. | genome, nei, neioff, pid, strand |
| `all.faa` | FASTA file of all found proteins. | N/A |
| `iscan.tsv` | Domain annotations from `interproscan.sh`. | pid, start, end, interpro, analysis |
| `archs.tsv` | Domain architectures of proteins. | pid, domain, start, end |
| `archs_pid_row.tsv` | Per-protein architecture summary. | pid, arch, arch_code |
| `archs_code.tsv` | PFAM-to-Unicode mapping. | domain, letter |
| `TGPD.tsv` | Taxa-genome-protein-domain relationships. | tax_id, genome, pid, domain |
| `absence_presence.tsv` | Presence/absence patterns of domains. | genome, tax_id |

Intermediary files (prefixed with `.`) are subject to change and serve internal purposes.

---

### Description of Common Columns

- `genome`: [NCBI Assembly Accession](https://support.nlm.nih.gov/kbArticle/?pn=KA-03451)
- `pid`: [NCBI Reference Sequence](https://www.ncbi.nlm.nih.gov/refseq/about/nonredundantproteins/)
- `taxid`: [NCBI Taxonomy ID](https://www.ncbi.nlm.nih.gov/books/NBK53758/#taxonomyqs.Data_Model)

#### `genome_metadata.tsv`

Metadata of the genome assemblies.
The data is obtained using the [*datasets NCBI utility*](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/command-line-tools/download-and-install/).

It looks like:

| genome | org | genus | tax_id | strain | status | level | date | owner | proj | completeness | contamination | cds | method | gc |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| GCF_001286845.1 | Bacillus subtilis | Bacillus | 1423 | NA | current | Contig | 2015-08-31 | EBI | PRJEB9876 | 98.13 | 2.54 | 4061 | NA | 43.5 |
| GCF_001286885.1 | Bacillus subtilis | Bacillus | 1423 | NA | current | Contig | 2015-08-31 | EBI | PRJEB9876 | 97.91 | 2.54 | 3945 | NA | 44 |
| GCF_000394295.1 | Enterococcus faecalis EnGen0248 | Enterococcus | 1158629 | SF19 | current | Scaffold | 2013-05-15 | Broad Institute | PRJNA88885 | 99.5 | 0.05 | 3007 | allpaths v. R41985 | 37 |


#### `taxallnomy_lin_name.tsv`

Taxonomic information obtained from [taxallnomy](https://sourceforge.net/projects/taxallnomy/).

It looks like:

| tax_id | spKin | kingdom | sbKin | spPhy | phylum | sbPhy | inPhy | spCla | class | sbCla | inCla | Coh | sbCoh | spOrd | order | sbOrd | inOrd | prOrd | spFam | family | sbFam | Tri | sbTri | genus | sbGen | Sec | sbSec | Ser | sbSer | Sgr | sbSgr | species | Fsp | sbSpe | Var | sbVar | For | Srg | Srt | Str | Iso |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | spKin_in_root | Kin_in_root | sbKin_in_root | spPhy_in_root | Phy_in_root | sbPhy_in_root | inPhy_in_root | spCla_in_root | Cla_in_root | sbCla_in_root | inCla_in_root | Coh_in_root | sbCoh_in_root | spOrd_in_root | Ord_in_root | sbOrd_in_root | inOrd_in_root | prOrd_in_root | spFam_in_root | Fam_in_root | sbFam_in_root | Tri_in_root | sbTri_in_root | Gen_in_root | sbGen_in_root | Sec_in_root | sbSec_in_root | Ser_in_root | sbSer_in_root | Sgr_in_root | sbSgr_in_root | Spe_in_root | Fsp_in_root | sbSpe_in_root | Var_in_root | sbVar_in_root | For_in_root | Srg_in_root | Srt_in_root | Str_in_root | Iso_in_root |
| 131567 | spKin_in_cellular organisms | Kin_in_cellular organisms | sbKin_in_cellular organisms | spPhy_in_cellular organisms | Phy_in_cellular organisms | sbPhy_in_cellular organisms | inPhy_in_cellular organisms | spCla_in_cellular organisms | Cla_in_cellular organisms | sbCla_in_cellular organisms | inCla_in_cellular organisms | Coh_in_cellular organisms | sbCoh_in_cellular organisms | spOrd_in_cellular organisms | Ord_in_cellular organisms | sbOrd_in_cellular organisms | inOrd_in_cellular organisms | prOrd_in_cellular organisms | spFam_in_cellular organisms | Fam_in_cellular organisms | sbFam_in_cellular organisms | Tri_in_cellular organisms | sbTri_in_cellular organisms | Gen_in_cellular organisms | sbGen_in_cellular organisms | Sec_in_cellular organisms | sbSec_in_cellular organisms | Ser_in_cellular organisms | sbSer_in_cellular organisms | Sgr_in_cellular organisms | sbSgr_in_cellular organisms | Spe_in_cellular organisms | Fsp_in_cellular organisms | sbSpe_in_cellular organisms | Var_in_cellular organisms | sbVar_in_cellular organisms | For_in_cellular organisms | Srg_in_cellular organisms | Srt_in_cellular organisms | Str_in_cellular organisms | Iso_in_cellular organisms |
| 2157 | Archaea | Kin_in_Archaea | sbKin_in_Archaea | spPhy_in_Archaea | Phy_in_Archaea | sbPhy_in_Archaea | inPhy_in_Archaea | spCla_in_Archaea | Cla_in_Archaea | sbCla_in_Archaea | inCla_in_Archaea | Coh_in_Archaea | sbCoh_in_Archaea | spOrd_in_Archaea | Ord_in_Archaea | sbOrd_in_Archaea | inOrd_in_Archaea | prOrd_in_Archaea | spFam_in_Archaea | Fam_in_Archaea | sbFam_in_Archaea | Tri_in_Archaea | sbTri_in_Archaea | Gen_in_Archaea | sbGen_in_Archaea | Sec_in_Archaea | sbSec_in_Archaea | Ser_in_Archaea | sbSer_in_Archaea | Sgr_in_Archaea | sbSgr_in_Archaea | Spe_in_Archaea | Fsp_in_Archaea | sbSpe_in_Archaea | Var_in_Archaea | sbVar_in_Archaea | For_in_Archaea | Srg_in_Archaea | Srt_in_Archaea | Str_in_Archaea | Iso_in_Archaea |
| 3366610 | Archaea | Methanobacteriati | sbKin_in_Methanobacteriati | spPhy_in_Methanobacteriati | Phy_in_Methanobacteriati | sbPhy_in_Methanobacteriati | inPhy_in_Methanobacteriati | spCla_in_Methanobacteriati | Cla_in_Methanobacteriati | sbCla_in_Methanobacteriati | inCla_in_Methanobacteriati | Coh_in_Methanobacteriati | sbCoh_in_Methanobacteriati | spOrd_in_Methanobacteriati | Ord_in_Methanobacteriati | sbOrd_in_Methanobacteriati | inOrd_in_Methanobacteriati | prOrd_in_Methanobacteriati | spFam_in_Methanobacteriati | Fam_in_Methanobacteriati | sbFam_in_Methanobacteriati | Tri_in_Methanobacteriati | sbTri_in_Methanobacteriati | Gen_in_Methanobacteriati | sbGen_in_Methanobacteriati | Sec_in_Methanobacteriati | sbSec_in_Methanobacteriati | Ser_in_Methanobacteriati | sbSer_in_Methanobacteriati | Sgr_in_Methanobacteriati | sbSgr_in_Methanobacteriati | Spe_in_Methanobacteriati | Fsp_in_Methanobacteriati | sbSpe_in_Methanobacteriati | Var_in_Methanobacteriati | sbVar_in_Methanobacteriati | For_in_Methanobacteriati | Srg_in_Methanobacteriati | Srt_in_Methanobacteriati | Str_in_Methanobacteriati | Iso_in_Methanobacteriati |

#### `genomes_ranks.tsv`

Taxonomic ranks per assembly.

It looks like:

| genome | tax_id | superkingdom | Kin | sbKin | spPhy | phylum | sbPhy | inPhy | spCla | class | sbCla | inCla | Coh | sbCoh | spOrd | order | sbOrd | inOrd | prOrd | spFam | family | sbFam | Tri | sbTri | genus | sbGen | Sec | sbSec | Ser | sbSer | Sgr | sbSgr | species | Fsp | sbSpe | Var | sbVar | For | Srg | Srt | Str | Iso |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| GCF_004214875.1 | 1193712 | Bacteria | Bacillati | sbKin_of_Mycoplasmatota | spPhy_of_Mycoplasmatota | Mycoplasmatota | sbPhy_of_Mollicutes | inPhy_of_Mollicutes | spCla_of_Mollicutes | Mollicutes | sbCla_of_Acholeplasmatales | inCla_of_Acholeplasmatales | Coh_of_Acholeplasmatales | sbCoh_of_Acholeplasmatales | spOrd_of_Acholeplasmatales | Acholeplasmatales | sbOrd_of_Acholeplasmataceae | inOrd_of_Acholeplasmataceae | prOrd_of_Acholeplasmataceae | spFam_of_Acholeplasmataceae | Acholeplasmataceae | sbFam_of_Candidatus Phytoplasma | Tri_of_Candidatus Phytoplasma | sbTri_of_Candidatus Phytoplasma | Candidatus Phytoplasma | sbGen_of_16SrI (Aster yellows group) | Sec_of_16SrI (Aster yellows group) | sbSec_of_16SrI (Aster yellows group) | Ser_of_16SrI (Aster yellows group) | sbSer_of_16SrI (Aster yellows group) | 16SrI (Aster yellows group) | sbSgr_of_'Catharanthus roseus' aster yellows phytoplasma | 'Catharanthus roseus' aster yellows phytoplasma | Fsp_in_'Catharanthus roseus' aster yellows phytoplasma | sbSpe_in_'Catharanthus roseus' aster yellows phytoplasma | Var_in_'Catharanthus roseus' aster yellows phytoplasma | sbVar_in_'Catharanthus roseus' aster yellows phytoplasma | For_in_'Catharanthus roseus' aster yellows phytoplasma | Srg_in_'Catharanthus roseus' aster yellows phytoplasma | Srt_in_'Catharanthus roseus' aster yellows phytoplasma | Str_in_'Catharanthus roseus' aster yellows phytoplasma | Iso_in_'Catharanthus roseus' aster yellows phytoplasma |
| GCF_000744065.1 | 1520703 | Bacteria | Bacillati | sbKin_of_Mycoplasmatota | spPhy_of_Mycoplasmatota | Mycoplasmatota | sbPhy_of_Mollicutes | inPhy_of_Mollicutes | spCla_of_Mollicutes | Mollicutes | sbCla_of_Acholeplasmatales | inCla_of_Acholeplasmatales | Coh_of_Acholeplasmatales | sbCoh_of_Acholeplasmatales | spOrd_of_Acholeplasmatales | Acholeplasmatales | sbOrd_of_Acholeplasmataceae | inOrd_of_Acholeplasmataceae | prOrd_of_Acholeplasmataceae | spFam_of_Acholeplasmataceae | Acholeplasmataceae | sbFam_of_Candidatus Phytoplasma | Tri_of_Candidatus Phytoplasma | sbTri_of_Candidatus Phytoplasma | Candidatus Phytoplasma | sbGen_of_16SrI (Aster yellows group) | Sec_of_16SrI (Aster yellows group) | sbSec_of_16SrI (Aster yellows group) | Ser_of_16SrI (Aster yellows group) | sbSer_of_16SrI (Aster yellows group) | 16SrI (Aster yellows group) | sbSgr_of_'Chrysanthemum coronarium' phytoplasma | 'Chrysanthemum coronarium' phytoplasma | Fsp_in_'Chrysanthemum coronarium' phytoplasma | sbSpe_in_'Chrysanthemum coronarium' phytoplasma | Var_in_'Chrysanthemum coronarium' phytoplasma | sbVar_in_'Chrysanthemum coronarium' phytoplasma | For_in_'Chrysanthemum coronarium' phytoplasma | Srg_in_'Chrysanthemum coronarium' phytoplasma | Srt_in_'Chrysanthemum coronarium' phytoplasma | Str_in_'Chrysanthemum coronarium' phytoplasma | Iso_in_'Chrysanthemum coronarium' phytoplasma |
| GCF_009268075.1 | 295320 | Bacteria | Bacillati | sbKin_of_Mycoplasmatota | spPhy_of_Mycoplasmatota | Mycoplasmatota | sbPhy_of_Mollicutes | inPhy_of_Mollicutes | spCla_of_Mollicutes | Mollicutes | sbCla_of_Acholeplasmatales | inCla_of_Acholeplasmatales | Coh_of_Acholeplasmatales | sbCoh_of_Acholeplasmatales | spOrd_of_Acholeplasmatales | Acholeplasmatales | sbOrd_of_Acholeplasmataceae | inOrd_of_Acholeplasmataceae | prOrd_of_Acholeplasmataceae | spFam_of_Acholeplasmataceae | Acholeplasmataceae | sbFam_of_Candidatus Phytoplasma | Tri_of_Candidatus Phytoplasma | sbTri_of_Candidatus Phytoplasma | Candidatus Phytoplasma | sbGen_unclassified Candidatus Phytoplasma | Sec_of_'Cynodon dactylon' phytoplasma | sbSec_of_'Cynodon dactylon' phytoplasma | Ser_of_'Cynodon dactylon' phytoplasma | sbSer_of_'Cynodon dactylon' phytoplasma | Sgr_of_'Cynodon dactylon' phytoplasma | sbSgr_of_'Cynodon dactylon' phytoplasma | 'Cynodon dactylon' phytoplasma | Fsp_in_'Cynodon dactylon' phytoplasma | sbSpe_in_'Cynodon dactylon' phytoplasma | Var_in_'Cynodon dactylon' phytoplasma | sbVar_in_'Cynodon dactylon' phytoplasma | For_in_'Cynodon dactylon' phytoplasma | Srg_in_'Cynodon dactylon' phytoplasma | Srt_in_'Cynodon dactylon' phytoplasma | Str_in_'Cynodon dactylon' phytoplasma | Iso_in_'Cynodon dactylon' phytoplasma |

#### `genomes/genomes.tsv`

Genomes that were downloaded,
and are ready for analysis.

It looks like:

| id | genome | refseq | version |
| --- | --- | --- | --- |
| 394295 | GCF_000394295.1 | True | 1 |
| 1286845 | GCF_001286845.1 | True | 1 |
| 1286885 | GCF_001286885.1 | True | 1 |


#### `genomes/not_found.tsv`

Genomes that weren't found, due to
having an unexistent ID or due to a network failure.

Usually _assembly IDs_ end on _0_ ar _5_ and the version number is tipycally at most _2_.

However, the pipeline considers anything that matches the following _regular expression_:
+ `GC[AF]_\d+\.\d`

It looks like:

| id | genome | refseq | version |
| --- | --- | --- | --- |
| 175795 | GCF_000175795.2 | True | 2 |
| 175899 | GCF_000175899.3 | True | 3 |
| 175938 | GCA_000175938.4 | False | 4 |


#### `hmmer.tsv`

Table of proteins that
have a hit with the input query domains.

It looks like:

| genome | pid | query | score | evalue | start | end | pid_txt | query_txt |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| GCF_000003925.1 | WP_003193395.1 | PF04740.17 | 83.16720581054688 | 6.70778390272961e-24 | 3 | 217 | T7SS effector LXG polymorphic toxin [Bacillus mycoides] | LXG |
| GCF_000003925.1 | WP_033734444.1 | PF04740.17 | 45.65201187133789 | 2.073188262284606e-12 | 7 | 186 | T7SS effector LXG polymorphic toxin [Bacillus mycoides] | LXG |
| GCF_000003925.1 | WP_033734479.1 | PF04740.17 | 45.274600982666016 | 2.7053982418375776e-12 | 7 | 181 | T7SS effector LXG polymorphic toxin [Bacillus mycoides] | LXG |

#### `neighbors.tsv`

Table of upstream and downstream
gene neighbors to the protein hits.

The `neioff` column is an offset from the hit position:
+ `-n` marks how many genes downstream the neighbor is.
+ `+n` marks how many genes upstream the neighbor is.
+ `0` position marks the subject protein.

The `order` column is the order of each protein as they appear on the contig.

The last columns are named as the query domains, and mark by which query that neighbor was found.
They are useful as filters to subset the _neighbors table_ to only neighbors of a given query.

The `nei` column means *neighborhood index*, and is a counter of the neighbors of a single genome (assembly).

To generate a single `neighborhood ID` a combination of _genome_ and _nei_ suffices.
To generate a single `neighbor entry ID` a combination of the _genome_, _nei_, and _neioff_ suffices. 

It looks like:

| genome | nei | neioff | order | pid | gene | product | start | end | strand | frame | locus_tag | contig | PF04493.19 | PF04740.17 | PF14431.11 | PF14449.11 |
| ------ | --- | ------ | ----- | --- | ---- | ------- | ----- | --- | ------ | ----- | --------- | ------ | ---------- | ---------- | ---------- | ---------- |
| GCF_000003925.1 | 1 | -12 | 1646 | WP_002126702.1 | exsE | exosporium protein ExsE | 1699037 | 1699993 | + | 0 | BMYCO0001_RS08545 | NZ_CM000742.1 | FALSE | TRUE | FALSE | FALSE |
| GCF_000003925.1 | 1 | -11 | 1645 | WP_016126754.1 | NA | hypothetical protein | 1697970 | 1699040 | + | 0 | BMYCO0001_RS08540 | NZ_CM000742.1 | FALSE | TRUE | FALSE | FALSE |
| GCF_000003925.1 | 1 | -10 | 1644 | WP_002126705.1 | NA | hypothetical protein | 1697534 | 1697977 | + | 0 | BMYCO0001_RS08535 | NZ_CM000742.1 | FALSE | TRUE | FALSE | FALSE |


#### `all.faa`

FASTA file of all unique proteins
that were found by _pandoomain_,
including those that are neighbors to
the subject proteins (hits).

It looks like:

``` faa
>WP_000141959.1 TIGR01741 family protein [Staphylococcus aureus]
MTFEEKLNEMYNEIANKISGMIPVEWEKVYTMAYIDDEGGEVFYYYTEPGSTELYYYTSVLNKYDILESEFMDSAYELYK
QFQNLRELFIEEGLEPWTSCEFDFTREGELKVSFDYIDWINTEFDQLGRQNYYMYKKFGVIPEMEYEMEEVKEIEQYIKE
QDEAEL
>WP_000141960.1 TIGR01741 family protein [Staphylococcus aureus]
MTFEEKLNEMYNEIANKISGMIPVEWEKVYTMAYIDDEGGEVFYYYTEPGSTELYYYTSVLNKYDILESEFMDSAYELYK
QFQNLRELFIEEGLEPWTSCEFDFTREGELKVSFDYIDWINTEFDQLGRQNYYMYKKFGVIPEMEYEMEEVKQIEQYIKE
QEETNL
>WP_000141961.1 MULTISPECIES: TIGR01741 family protein [Staphylococcus]
MTFEEKLNEMYNEIANKISGMIPVEWEQVYTIAYVNDRGGEVIFNYTKPGSDELNYYTDISRDYNVSEEIFDDLWMNLYY
LFKNLRNLFKTEGHEPWTSCEFDFTRDGKLNVSFDYIDWIKLGLGPLARENYYMYKKFGVIPEMEEIKEIVQYIKEQDEA
EI
```

#### `iscan.tsv`

Domain annotation of
the proteins that were found by
_pandoomain_ (proteins contained on `all.faa`).

The annotation is performed by [`interproscan.sh`](https://github.com/ebi-pf-team/interproscan).

It looks like:

| pid | md5 | length | analysis | memberDB | memberDB_txt | start | end | score | recommended | date | interpro | interpro_txt | GO | residue |
| --- | --- | ------ | -------- | -------- | ------------ | ----- | --- | ----- | ----------- | ---- | -------- | ------------ | -- | ------- |
| WP_231825678.1 | 83b0e6cc3855c39d370be75a9ecfb444 | 221 | Gene3D | G3DSA:3.30.2170.10 | archaeoglobus fulgidus dsm 4304 superfamily | 1 | 214 | 8.5E-92 | T | 05-11-2024 | - | - | - | - |
| WP_231825678.1 | 83b0e6cc3855c39d370be75a9ecfb444 | 221 | PANTHER | PTHR28511 | ENDONUCLEASE V | 5 | 211 | 1.3E-51 | T | 05-11-2024 | IPR007581 | Endonuclease V | GO:0003727(PANTHER)\|GO:0004519(InterPro)\|GO:0006281(InterPro)\|GO:0016891(PANTHER)\|GO:0043737(PANTHER) | - |
| WP_231825678.1 | 83b0e6cc3855c39d370be75a9ecfb444 | 221 | CDD | cd06559 | Endonuclease_V | 3 | 211 | 2.33121E-104 | T | 05-11-2024 | IPR007581 | Endonuclease V | GO:0004519(InterPro)\|GO:0006281(InterPro) | - |

#### `archs.tsv`

Each row is a PFAM domain.
It summarizes all the found PFAM domains.

It looks like:

| pid | domain | order | start | end | length | domain_txt |
| --- | --- | --- | --- | --- | --- | --- |
| NP_312948.1 | PF04493 | 1 | 12 | 206 | 223 | Endonuclease V |
| NP_388563.2 | PF04740 | 1 | 2 | 201 | 669 | LXG domain of WXG superfamily |
| NP_388563.2 | PF13930 | 2 | 525 | 654 | 669 | DNA/RNA non-specific endonuclease |

#### `archs_pid_row.tsv`

Same information as in `archs.tsv`,
but each row in this table is a protein.
It summarizes its domain architecture,
Represented either as a list of PFAMs IDs or
a string using the PFAMs single letter codes (explained at [`archs_code.tsv`](#archs_code.tsv)).

It looks like:

| pid | arch | ndoms | length | arch_code |
| --- | --- | --- | --- | --- |
| NP_312948.1 | PF04493 | 1 | 223 | Ţ |
| NP_388563.2 | PF04740,PF13930 | 2 | 669 | ťě |
| NP_389781.1 | PF04740,PF14411 | 2 | 600 | ťċ |


#### `archs_code.tsv`

Each _PFAM_ domain is converted to a single character representation.
The mapping is generated by adding `+33` to the _PFAM ID_ and then
interpreting the results as a _Unicode Point_.

The resulting characters are summarized in this table.

+ This R function generates the mapping:
```R
one_lettercode <- function(doms) {
  library(stringr)

  OFFSET <- 33
  PF_INT_LEN <- 5
  PF_LEAD_CHAR <- "PF"

  doms <- unique(doms)

  pfam_chars <- str_extract(doms, "\\d+")
  stopifnot("Bad PFAM ID." = all(str_length(pfam_chars) == PF_INT_LEN))

  pfam_ints <- as.integer(pfam_chars)
  stopifnot("Some extracted PFAM IDs are NA." = all(!is.na(pfam_ints)))

  stopifnot("Unicode points out of range." = all((pfam_ints + OFFSET) <= 0x10FFFF))
  pfam_codes <- strsplit(intToUtf8(pfam_ints + OFFSET), "")[[1]]

  stopifnot("Conversion to utf-8 failed." = length(pfam_codes) == length(doms))
  OUT <- pfam_codes
  names(OUT) <- doms

  OUT
}
```

+ This R function reverts the mapping:
```R
code_to_pfam <- function(codes) {
  library(stringr)
  library(purrr)
  
  OFFSET <- 33
  PF_INT_LEN <- 5
  PF_LEAD_CHAR <- "PF"
  TOTAL_LEN <- PF_INT_LEN + str_length(PF_LEAD_CHAR)

  pfam_ints <- utf8ToInt(codes) - OFFSET
  pfam_chars <- as.character(pfam_ints)

  appends <- map_chr(
    PF_INT_LEN - str_length(pfam_chars),
 \(x) ifelse(x > 0, str_flatten(rep("0", x)), "")
 )

  OUT <- str_c(PF_LEAD_CHAR, appends, pfam_chars)
  stopifnot("Bad PFAM ID" = all(str_length(OUT) == TOTAL_LEN))

  OUT
}
```

It looks like:

| domain | letter |
| --- | --- |
| PF04493 | Ţ |
| PF04740 | ť |
| PF13930 | ě |

### `TGPD.tsv`

Short for _Taxa, Genome, Protein, and Domain_. This table
joins those four things. In a way, it is a summary of all the pipeline results.

It looks like:

| tax_id | genome | pid | domain |
| --- | --- | --- | --- |
| 1193712 | GCF_004214875.1 | NA | NA |
| 1520703 | GCF_000744065.1 | NA | NA |
| 295320 | GCF_009268075.1 | NA | NA |

#### `absence_presence.tsv`

Contains the hits and neighbor proteins annotated domains.
Each row is a genome with its patterns of absence or presence of all the domains found by the pipeline.

If only the initial query domains are wanted a simple selection of the correct columns will do.

It looks like:

| genome | tax_id | species | PF00015 | PF00028 | PF00082 | PF00092 | PF00126 | PF00226 | PF00232 | PF00246 | PF00353 | PF00361 | PF00383 | PF00392 | PF00395 | PF00404 | PF00413 | PF00415 | PF00501 | PF00545 | PF00550 | PF00553 | PF00583 | PF00648 | PF00652 | PF00668 | PF00672 | PF00691 | PF00795 | PF00817 | PF00856 | PF00963 | PF01035 | PF01079 | PF01344 | PF01435 | PF01441 | PF01471 | PF01473 | PF01476 | PF01541 | PF01580 | PF01833 | PF01839 | PF01841 | PF01909 | PF02195 | PF02233 | PF02368 | PF02470 | PF02563 | PF02661 | PF02687 | PF03466 | PF03496 | PF03497 | PF03527 | PF03534 | PF03564 | PF04233 | PF04493 | PF04717 | PF04740 | PF04829 | PF04830 | PF05345 | PF05488 | PF05521 | PF05593 | PF05594 | PF05860 | PF05954 | PF06013 | PF06037 | PF06259 | PF07461 | PF07508 | PF07591 | PF07661 | PF08239 | PF09000 | PF09136 | PF09346 | PF09533 | PF10145 | PF11311 | PF11429 | PF11798 | PF12106 | PF12255 | PF12256 | PF12639 | PF12698 | PF12729 | PF12802 | PF12836 | PF13018 | PF13125 | PF13193 | PF13205 | PF13332 | PF13385 | PF13395 | PF13408 | PF13432 | PF13488 | PF13517 | PF13640 | PF13665 | PF13699 | PF13753 | PF13780 | PF13930 | PF13946 | PF14021 | PF14029 | PF14107 | PF14410 | PF14411 | PF14412 | PF14414 | PF14424 | PF14431 | PF14433 | PF14436 | PF14437 | PF14448 | PF14449 | PF14517 | PF14657 | PF14751 | PF15524 | PF15526 | PF15529 | PF15532 | PF15534 | PF15538 | PF15540 | PF15542 | PF15545 | PF15604 | PF15605 | PF15607 | PF15633 | PF15636 | PF15637 | PF15640 | PF15643 | PF15644 | PF15647 | PF15648 | PF15649 | PF15650 | PF15652 | PF15653 | PF15657 | PF16640 | PF16888 | PF17642 | PF17957 | PF17963 | PF18431 | PF18451 | PF18664 | PF18798 | PF18807 | PF18884 | PF18998 | PF19127 | PF19458 | PF20041 | PF20148 | PF20410 | PF21111 | PF21431 | PF21724 | PF21725 | PF21814 | PF22148 | PF22178 | PF22596 | PF22783 | superkingdom | phylum | class | order | family | genus |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| GCF_004214875.1 | 1193712 | 'Catharanthus roseus' aster yellows phytoplasma | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | Bacteria | Mycoplasmatota | Mollicutes | Acholeplasmatales | Acholeplasmataceae | Candidatus Phytoplasma |
| GCF_000744065.1 | 1520703 | 'Chrysanthemum coronarium' phytoplasma | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | Bacteria | Mycoplasmatota | Mollicutes | Acholeplasmatales | Acholeplasmataceae | Candidatus Phytoplasma |
| GCF_009268075.1 | 295320 | 'Cynodon dactylon' phytoplasma | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | FALSE | Bacteria | Mycoplasmatota | Mollicutes | Acholeplasmatales | Acholeplasmataceae | Candidatus Phytoplasma |

---

This document provides a comprehensive overview of Pandoomain's inputs, configurations, and output files. For further details, refer to individual module documentation or contact the project maintainers.
