#!/usr/bin/Rscript

suppressPackageStartupMessages({
  library(tidyverse)
})

args <- commandArgs(trailingOnly = TRUE)

# Globals ----

HMMER <- args[1]
# HMMER <- "tests/results/hmmer_raw.tsv"

# Code ----

hmmer <- read_tsv(HMMER)

hmmer <- hmmer |>
  filter(included) |>
  distinct(genome, pid, query, query_description)

hmmer |>
  format_tsv() |>
  writeLines(stdout(), sep = "")
