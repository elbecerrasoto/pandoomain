from pathlib import Path

from snakemake.utils import min_version

import utils as ut

min_version("8.5.3")


configfile: "config/config.yaml"


envvars:
    "SNAKEMAKE_OUTPUT_CACHE",


GENOME_REGEX = r"GC[AF]_\d+\.\d"


wildcard_constraints:
    genome=GENOME_REGEX,


# Config dependant

IN_GENOMES = Path(config["genomes"])
IN_QUERIES = Path(config["queries"])


RESULTS = Path(config["results"])
USED_GENOMES = RESULTS / "genomes.tsv"
RESULTS_GENOMES = RESULTS / "genomes"


# Optionals keys on YAML
ONLY_REFSEQ = config.setdefault("only_refseq", False)
N = int(config.setdefault("neighborhood", 0))

DIAMOND_ARGS = config.setdefault("diamond_args", "")

PAIR = config.setdefault("pair", None)
FILTERING_DOMS = config.setdefault("filtering_doms", None)

OFFLINE_MODE = config.setdefault("offline", False)


RESULTS.mkdir(
    parents=True, exist_ok=True
)  # Need it 'cause the output of sort_filter_genomes
GENOMES = ut.sort_filter_genomes(IN_GENOMES, USED_GENOMES, ONLY_REFSEQ)

CDS_HEADER_L = [
    "genome",
    "pid",
    "gene",
    "order",
    "start",
    "end",
    "contig",
    "strand",
    "locus_tag",
    "product",
]
CDS_HEADER = "\t".join(CDS_HEADER_L)

ISCAN_HEADER_L = [
    "pid",
    "md5",
    "length",
    "analysis",
    "memberDB",
    "memberDB_txt",
    "start",
    "end",
    "score",
    "recommended",
    "date",
    "interpro",
    "interpro_txt",
    "GO",
    "residue",
]
ISCAN_HEADER = "\t".join(ISCAN_HEADER_L)

ISCAN_XML = Path(".iscan.xml")
ISCAN_TSV = Path("iscan.tsv")

BLASTS_FAA = Path("blasts.faa")
BLASTS_TSV = Path("blasts.tsv")
BLASTS_PID = Path(".blasts_pids.txt")


IN_BLAST_FIELDS = Path("config/blast_fields.tsv")
BLAST_FIELDS = ut.get_blast_fields(IN_BLAST_FIELDS)
BLAST_FORMAT = " ".join(BLAST_FIELDS)

BLAST_FORMAT_RENAMES = {"qseqid": "query", "sseqid": "pid"}
d = BLAST_FORMAT_RENAMES
blast_renamed = [d[i] if i in d.keys() else i for i in BLAST_FIELDS]

BLAST_HEADER = "\t".join(["genome"] + blast_renamed)


ALL_BLASTS = ut.for_all_genomes("_blast.tsv", RESULTS_GENOMES, GENOMES)
ALL_HITS = ut.for_all_genomes("_hits.tsv", RESULTS_GENOMES, GENOMES)
ALL_HOODS = ut.for_all_genomes("_neighborhoods.tsv", RESULTS_GENOMES, GENOMES)


def main():
    if not OFFLINE_MODE:
        assert ut.is_internet_on(), ut.bold_red("No network connection.")

    assert IN_GENOMES.exists(), (
        ut.bold_red("Input genome assembly list file not found.")
        + f"\nTried to look it up at: {IN_GENOMES}."
    )

    assert IN_QUERIES.exists(), (
        ut.bold_red("Input query file not found.")
        + f"\nTried to look it up at: {IN_QUERIES}."
    )
    assert IN_BLAST_FIELDS.exists(), (
        ut.bold_red("Input blast fields file not found.")
        + f"\nTried to look it up at: {IN_BLAST_FIELDS}."
    )


main()
