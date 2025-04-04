#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
})

argv <- commandArgs(trailingOnly = TRUE)

DEBUG <- FALSE

if (DEBUG) {
  TAXA <- "tests/results/genomes_ranks.tsv"
  PROTEINS <- "tests/results/hmmer.tsv"
  DOMAINS <- "tests/results/archs.tsv"
  OUT_TGPD <- "tgpd.tsv"
  OUT_ABSENCE_PRESENCE <- "abs.tsv"
} else {
  # Inputs
  TAXA <- argv[[1]]
  PROTEINS <- argv[[2]]
  DOMAINS <- argv[[3]]

  # Outputs
  OUT_TGPD <- argv[[4]]
  OUT_ABSENCE_PRESENCE <- argv[[5]]
}


TAXA_SEL <- c(
  "genome", "tax_id",
  "superkingdom",
  "phylum", "class", "order",
  "family", "genus", "species"
)


ranks <- read_tsv(TAXA, show_col_types = FALSE) |>
  select(all_of(TAXA_SEL))
proteins <- read_tsv(PROTEINS, show_col_types = FALSE) |>
  select(genome, pid)
domains <- read_tsv(DOMAINS, show_col_types = FALSE) |>
  select(pid, domain)

# TaxID 1-m Genomes m-m Proteins m-m Domains
# 1-1 one-to-one
# 1-m one-to-many
# m-m many-to-many

TGPD <- ranks |>
  select(tax_id, genome) |>
  left_join(proteins, join_by(genome),
    relationship = "many-to-many"
  ) |>
  left_join(domains, join_by(pid),
    relationship = "many-to-many"
  )

absence_presence <- TGPD |>
  group_by(genome) |>
  summarize(
    tax_id = unique(tax_id),
    domains = str_flatten(unique(domain), collapse = ",")
  ) |>
  left_join(ranks, join_by(genome, tax_id)) |>
  relocate(genome, tax_id, species)

write_tsv(TGPD, OUT_TGPD)
write_tsv(absence_presence, OUT_ABSENCE_PRESENCE)
