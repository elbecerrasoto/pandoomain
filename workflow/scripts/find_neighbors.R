#!/usr/bin/env Rscript

# Given a mappings file and a cds file:
# Extract neighbors

suppressPackageStartupMessages({
  library(tidyverse)
  library(stringr)
  library(glue)
})


args <- commandArgs(trailingOnly = TRUE)


MAPPINGS <- args[1]
N <- as.integer(args[2])
CDS <- args[3]

# MAPPINGS <- "tests/results/mappings.tsv"
# N <- as.integer("12")
# CDS <- "tests/results/genomes/GCF_001286845.1/GCF_001286845.1_cds.tsv"

if (N < 1) {
  writeLines("", stdout(), sep = "")
  quit(save = "no", status = 0)
}


GENOME_RE <- "GC[AF]_[0-9]+"

extract_genome <- function(path) {
  str_extract(path, "GC[AF]_[0-9]+\\.[0-9]")
}

GENOME <- extract_genome(CDS)


neighbor_seq <- function(down, up) {
  if (down > 0) {
    downS <- -seq(down, 1, -1)
  } else {
    downS <- NULL
  }

  midS <- 0

  if (up > 0) {
    upS <- seq(1, up, 1)
  } else {
    upS <- NULL
  }

  c(downS, midS, upS)
}

# Code ----


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


neighborhoods <- vector(mode = "list", length = nrow(hits))
for (row in seq_len(nrow(hits))) {
  # Globals
  hit <- hits[row, ]
  # N <- N
  # cds <- cds
  # neighborhoods <- neighborhoods

  # Vars Definition, Field Extraction
  hlocus <- hit$locus_tag
  horder <- hit$order

  hrow <- hit$row
  hcontig <- hit$contig

  genome <- hit$genome
  q_alias <- hit$q_alias
  query <- hit$query

  bounds <- contigs |> filter(contig == hcontig)
  low <- bounds$starto # bound low
  high <- bounds$endo # bound high

  # Computations

  d2low <- abs(horder - low)
  d2high <- abs(high - horder)

  on_range_low <- horder - N >= low
  on_range_high <- horder + N <= high

  row_down <- ifelse(on_range_low, hrow - N, hrow - d2low)
  row_up <- ifelse(on_range_high, hrow + N, hrow + d2high)

  down <- ifelse(on_range_low, N, d2low)
  up <- ifelse(on_range_high, N, d2high)

  nseq <- neighbor_seq(down, up)

  neighborhood_id <- glue("{genome}_{hlocus}_{N}")

  x <- cds[row_down:row_up, ] |>
    mutate(
      Nid = neighborhood_id,
      Nseq = nseq,
      q_alias = q_alias,
      query = query
    ) |>
    relocate(Nid, Nseq, q_alias, query)

  neighborhoods[[row]] <- x
}

# Output to stdout
do.call(bind_rows, neighborhoods) |>
  format_tsv() |>
  writeLines(stdout(), sep = "")
