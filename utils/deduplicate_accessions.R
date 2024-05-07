#!/usr/bin/Rscript

suppressPackageStartupMessages({
  library(stringr)
  library(tidyverse)
})

args <- commandArgs(trailingOnly = TRUE)


# Globals ----


# Input
IN <- args[1] # "tests/genomes_messy.txt"


# Main ----

genomes <- read_tsv(IN, col_names = "accession", comment = "#") |>
  mutate(
    ref_seq = str_detect(accession, "^GCF_"),
    id = as.integer(
      str_extract(accession, "\\d+(?=\\.\\d+$)")
    ),
    version = as.integer(
      str_extract(accession, "\\d+$")
    )
  )


best <- genomes |>
  group_by(id) |>
  arrange(desc(ref_seq),
    desc(version),
    .by_group = TRUE
  ) |>
  summarize(accession_best = first(accession))


n_ids <- best |>
  nrow()

expected <- genomes |>
  pull(id) |>
  unique() |>
  length()

stopifnot(n_ids == expected)


best |>
  select(accession_best) |>
  format_tsv(col_names = FALSE) |>
  writeLines(stdout(), sep = "")
