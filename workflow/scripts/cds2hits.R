#!/usr/bin/Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(furrr)
})

args <- commandArgs(trailingOnly = TRUE)

# Globals ----

GPQ <- read_tsv(args[1])
CORES <- as.numeric(args[2])

CDS <- read_tsv(args[3], col_names = FALSE)[[1]]


# GPQ <- read_tsv("tests/results/genome_pid_query.tsv")
# CORES <- 12
# CDS <- c(
#   "tests/results/genomes/GCF_001286845.1/GCF_001286845.1_cds.tsv",
#   "tests/results/genomes/GCF_001286885.1/GCF_001286885.1_cds.tsv"
# )


# Code ----

plan(multisession, workers = CORES)

process_cds <- function(cds_path) {
  cds <- read_tsv(cds_path)
  out <- semi_join(cds, GPQ, join_by(pid)) |>
    left_join(GPQ, join_by(genome, pid))
  # assert order, start, end, contig, strand, locus_tag, product query, query_description
  # cannot be all NA
  remove(cds)
  out
}


process_cds <- possibly(
  process_cds,
  tibble()
)

OUT <- future_map(CDS, process_cds)

do.call(bind_rows, OUT) |>
  format_tsv() |>
  writeLines(stdout(), sep = "")
