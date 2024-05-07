#!/usr/bin/Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(stringr)
})

args <- commandArgs(trailingOnly = TRUE)


# Globals ----


MAPPINGS <- args[1]
# MAPPINGS <- "tests/results/mappings_raw.tsv"


# Main ----


mappings <- read_tsv(MAPPINGS)

mappings <- mappings |>
  group_by(q_alias, query, pid) |>
  summarize(
    domains = str_flatten(unique(domain), collapse = ";"),
    genomes = str_flatten(unique(genome), collapse = ";")
  )


mappings |>
  format_tsv() |>
  writeLines(stdout(), sep = "")
