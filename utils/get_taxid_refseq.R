#!/usr/bin/Rscript

sM <- suppressMessages
sM(library(tidyverse))
library(stringr)
library(glue)

args <- commandArgs(trailingOnly = TRUE)
TAXID <- args[1]
DIR <- ifelse(is.na(args[2]), getwd(), args[2])

OUT <- glue("{DIR}/{TAXID}_refseq.tsv")
cat(c(glue("Output file would be: {OUT}"), "\n"))

stopifnot(length(args) != 0)

cat("Get NCBI data\n")

system2("utils/get_taxid.sh", args = TAXID)

cat("Read data\n")

IN <- glue("{TAXID}.tsv")
# devnull <- file(nullfile(), open = "w")
# sink(devnull, type = "message")
datasets <- read_tsv(IN) |>
  janitor::clean_names() |>
  distinct(assembly_accession, .keep_all = TRUE)
# sink()
# close(devnull)

empty <- datasets |>
  map_lgl(\(x) all(is.na(x)))

datasets <- datasets[!empty]

ALL <- c(
  "assembly_accession",
  "ani_submitted_organism",
  "organism_taxonomic_id",
  "assembly_status",
  "assembly_level",
  "assembly_release_date",
  "assembly_bio_sample_owner_name",
  "assembly_bio_project_accession",
  "check_m_completeness",
  "check_m_contamination",
  "annotation_count_gene_protein_coding",
  "assembly_assembly_method",
  "assembly_stats_gc_percent"
)

cat("Selecting columns\n")

x <- datasets |>
  select(all_of(ALL)) |>
  rename(
    genome = assembly_accession,
    org = ani_submitted_organism,
    tax_id = organism_taxonomic_id,
    status = assembly_status,
    level = assembly_level,
    date = assembly_release_date,
    owner = assembly_bio_sample_owner_name,
    proj = assembly_bio_project_accession,
    completeness = check_m_completeness,
    contamination = check_m_contamination,
    n_cds = annotation_count_gene_protein_coding,
    method = assembly_assembly_method,
    gc = assembly_stats_gc_percent
  )


cat("Add RefSeq flag\n")

x <- x |>
  mutate(
    ref_seq = str_detect(genome, "^GCF_"),
    id = as.integer(
      str_extract(genome, "\\d+(?=\\.\\d+$)")
    ),
    version = as.integer(
      str_extract(genome, "\\d+$")
    )
  ) |>
  relocate(genome, ref_seq, id, version)

cat("Filter assemblies by 'current' flag\n")
cat("Filter assemblies by 'ref_seq' flag\n")
x <- x |>
  filter(ref_seq, status == "current")

cat("Write filtered assemblies to disk\n")

x |>
  write_tsv(OUT)