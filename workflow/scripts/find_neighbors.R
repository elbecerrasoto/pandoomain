#!/usr/bin/env Rscript

# Given a mappings file and a cds file:
# Extract neighbors

suppressPackageStartupMessages({
  library(tidyverse)
  library(stringr)
})


args <- commandArgs(trailingOnly = TRUE)


MAPPINGS <- args[1]
N <- args[2]
CDS <- args[3]

MAPPINGS <- "tests/results/mappings.tsv"
N <- as.integer("12")
CDS <- "tests/results/genomes/GCF_001286845.1/GCF_001286845.1_cds.tsv"



GENOME_RE <- "GC[AF]_[0-9]+"

extract_genome <- function(path) {
  str_extract(path, "GC[AF]_[0-9]+\\.[0-9]")
}

GENOME <- extract_genome(CDS)

mappings <- read_tsv(MAPPINGS)
cds <- read_tsv(CDS)

cds <- cds |>
  mutate(row = 1:nrow(cds)) |>
  relocate(row)

mappings <- mappings |>
  select(-domain) |>
  distinct()

hits <- mappings |>
  filter(genome == GENOME) |>
  left_join(cds, join_by(genome, pid))


contigs <- cds |>
  group_by(contig) |>
  summarize(
    starto = min(order),
    endo = max(order)
  ) |>
  ungroup()

contigs <- contigs |>
  mutate(cumg = cumsum(endo))


for (row in 1:nrow(hits)) {
  hit <- hits[row, ]
  horder <- hit$order
  hcontig <- hit$contig
  bounds <- contigs |> filter(contig == hcontig)
  min <- bounds$starto
  max <- bounds$endo
  print(bounds)
  o_down <- ifelse(horder - N >= min, horder - N, min)
  o_up <- ifelse(horder + N <= max, horder + N, max)
}
