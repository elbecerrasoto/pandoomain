#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
})

argv <- commandArgs(trailingOnly = TRUE)


# Inputs
TAXA <- argv[[1]]
GENOMES <- argv[[2]]
PROTEINS <- argv[[3]]
DOMAINS <- argv[[4]]

# Outputs
OUT_TGPD <- argv[[5]]
OUT_ABSENCE_PRESENCE <- argv[[6]]

## GENOMES <- "tests/results/genomes_metadata.tsv"
## PROTEINS <- "tests/results/hmmer.tsv"
## DOMAINS <- "tests/results/archs.tsv"
## TAXA <- "tests/results/genomes_ranks.tsv"


TAXA_SEL <- c(
  "genome", "tax_id",
  "superkingdom",
  "phylum", "class", "order",
  "family", "genus", "species"
)


ranks <- read_tsv(TAXA) |>
  select(all_of(TAXA_SEL))
genomes <- read_tsv(GENOMES) |>
  select(genome, tax_id) |>
  mutate(tax_id = as.integer(tax_id))
proteins <- read_tsv(PROTEINS) |>
  select(genome, pid)
domains <- read_tsv(DOMAINS) |>
  select(pid, domain)

# Taxid 1-m Genomes m-m Proteins m-m Domains
# 1-1 one-to-one
# 1-m one-to-many
# m-m many-to-many

TGPD <- genomes |>
  left_join(proteins, join_by(genome),
    relationship = "many-to-many"
  ) |>
  left_join(domains, join_by(pid),
    relationship = "many-to-many"
  )


# One Hot Encoding
absence_presence <- TGPD |>
  select(-pid) |>
  distinct() |>
  mutate(presence = TRUE) |>
  pivot_wider(
    names_from = domain,
    values_from = presence,
    values_fill = FALSE,
    names_sort = TRUE
  ) |>
  select(-any_of("NA"))


absence_presence <- absence_presence |>
  left_join(ranks, join_by(genome, tax_id)) |>
  relocate(genome, tax_id, species)


write_tsv(TGPD, OUT_TGPD)
write_tsv(absence_presence, OUT_ABSENCE_PRESENCE)
