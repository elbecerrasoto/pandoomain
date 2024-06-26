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


IN_GENOMES = Path(config["genomes"])
IN_QUERIES = Path(config["queries"])
IN_BLAST_FIELDS = Path("config/blast_fields.tsv")


ONLY_REFSEQ = config["only_refseq"]
N = config["neighborhood"]  # trigger a conditional rule

RESULTS = Path(config["results"])
USED_GENOMES = RESULTS / "genomes.tsv"
RESULTS_GENOMES = RESULTS / "genomes"


DIAMOND_ARGS = config["diamond_args"]
# PAIR = config["pair"] # trigger a conditional rule
# FILTERING_DOMS = config["filtering_domains"] # trigger a conditional rule

RESULTS.mkdir(
    parents=True, exist_ok=True
)  # Need it 'cause the output of sort_filter_genomes
GENOMES = ut.sort_filter_genomes(IN_GENOMES, USED_GENOMES, ONLY_REFSEQ)

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


BLAST_FIELDS = ut.get_blast_fields(IN_BLAST_FIELDS)
BLAST_FORMAT = " ".join(BLAST_FIELDS)

BLAST_FORMAT_RENAMES = {"qseqid": "query", "sseqid": "pid"}
d = BLAST_FORMAT_RENAMES
blast_renamed = [d[i] if i in d.keys() else i for i in BLAST_FIELDS]

BLAST_HEADER = "\t".join(["genome"] + blast_renamed)

OFFLINE_MODE = config["offline"]

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
