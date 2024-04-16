#!/usr/bin/Rscript

library(tidyverse)
args <- commandArgs(trailingOnly = TRUE)

# Globals ----

PIDS <- args[1]
# PIDS <- "tests/results/.blasts_pids.txt"
CDS <- args[2]
# CDS <- "tests/results/genomes/GCF_001286885.1/GCF_001286885.1_cds.tsv"


# Code ----

pids <- read_tsv(PIDS, col_names = "pid")
cds <- read_tsv(CDS)

cds |>
  semi_join(pids) |>
  format_tsv() |>
  writeLines(stdout(), sep = "")
