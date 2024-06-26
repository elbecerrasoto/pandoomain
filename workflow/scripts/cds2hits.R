#!/usr/bin/Rscript

suppressPackageStartupMessages({
  library(tidyverse)
})

args <- commandArgs(trailingOnly = TRUE)

# Globals ----

PIDS <- args[1]
CDS <- args[2]

PIDS <- "tests/results/.blasts_pids.txt"
CDS <- "tests/results/genomes/GCF_001286845.1/GCF_001286845.1_cds.tsv"


# Code ----

pids <- read_tsv(PIDS, col_names = "pid")
cds <- read_tsv(CDS)

cds |>
  semi_join(pids, join_by(pid)) |>
  format_tsv(col_names = F) |>
  writeLines(stdout(), sep = "")
