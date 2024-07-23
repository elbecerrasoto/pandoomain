#!/usr/bin/env Rscript

library(tidyverse)

args <- commandArgs(trailingOnly = TRUE)
IN <- args[1]

meta <- read_tsv(IN) |>
  janitor::clean_names() |>
  distinct(assembly_accession, .keep_all = TRUE)


ALL <- c(
  "assembly_accession",
  "organism_name",
  "organism_taxonomic_id",
  "organism_infraspecific_names_strain",
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


meta <- meta |>
  select(all_of(ALL)) |>
  rename(
    genome = assembly_accession,
    org = organism_name,
    tax_id = organism_taxonomic_id,
    strain = organism_infraspecific_names_strain,
    status = assembly_status,
    level = assembly_level,
    date = assembly_release_date,
    owner = assembly_bio_sample_owner_name,
    proj = assembly_bio_project_accession,
    completeness = check_m_completeness,
    contamination = check_m_contamination,
    cds = annotation_count_gene_protein_coding,
    method = assembly_assembly_method,
    gc = assembly_stats_gc_percent
  )

meta |>
  format_tsv() |>
  writeLines(stdout(), sep = "")
