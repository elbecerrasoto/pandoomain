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


neighborhoods <- vector(mode = "list", length = nrow(hits))
for (row in 1:nrow(hits)) {
  # Globals
  hit <- hits[row, ]
  # N <- N
  # cds <- cds
  # neighborhoods <- neighborhoods

  # Vars Definition, Field Extraction
  hpid <- hit$pid
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

  row_down <- ifelse(horder - N >= low, hrow - N, hrow - d2low)
  row_up <- ifelse(horder + N <= high, hrow + N, hrow + d2high)

  neighborhood_id <- glue("{genome}_{hpid}_{N}")

  x <- cds[row_down:row_up, ] |>
    mutate(
      Nid = neighborhood_id,
      q_alias = q_alias,
      query = query
    ) |>
    relocate(Nid, q_alias, query)

  neighborhoods[[row]] <- x
}


do.call(bind_rows, neighborhoods)
