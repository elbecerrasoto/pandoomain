#!/usr/bin/Rscript

# Send all output to stderr
# With exeption of last lines
# segmenTools is not well behaved
# so it sends messages to stdout
# that should be on stderr
sink(stderr(), type = "output")

suppressPackageStartupMessages({
  library(tidyverse)
  library(rlang) # warnings utils
  library(segmenTools)
  library(glue)
  library(yaml)
})


args <- commandArgs(trailingOnly = TRUE)


# Globals ----

HEADERS <- "config/headers.yaml"
GFF <- args[1]
# GFF <- "tests/results/genomes/GCF_001286845.1/GCF_001286845.1.gff"


OUT_COLS <- read_yaml(HEADERS)$CDS_HEADER


GENOME_RE <- "GC[FA]_[0-9]+\\.[0-9]"
GENOME <- str_extract(GFF, GENOME_RE)


# Helpers ----


read_gff <- function(path) {
  # 1. Read
  # 2. Remove pseudogenes
  # 3. Add neighbors, order column

  gff <- segmenTools::gff2tab(path) |>
    tibble() |>
    filter(feature == "CDS") |> # only CDS
    select_if({
      \(x) !(all(is.na(x)) | all(x == ""))
    }) # exclude empty cols

  # Remove pseudogenes
  if ("pseudo" %in% names(gff)) {
    gff <- gff |>
      filter(is.na(pseudo))
  }

  # Definition of neighbor
  # same contig, order by start position
  gff <- gff |>
    group_by(seqname) |>
    arrange(start) |>
    mutate(order = seq_along(start)) |>
    relocate(order) |>
    ungroup()

  # Sort to spot patterns
  gff <- gff |>
    arrange(seqname, order)

  gff
}


# Code ----

gff <- read_gff(GFF) |>
  rename(pid = protein_id, contig = seqname) |>
  mutate(genome = GENOME)


# manual test of missing cols
# gff <- gff |>
#   select(-pid,
#          -genome)


present <- OUT_COLS %in% names(gff)
absent <- OUT_COLS[!present]

msg <- glue("The following columns were not present:\n{str_flatten(absent, collapse = ' ')}\nOn the file:\n{GFF}")

if (!all(present)) {
  warn(msg)
}

# add missing features
absent_defaults <- setNames(as.list(rep(NA, length(absent))), absent)
add_absent <- partial(add_column, .data = gff)

gff <- do.call(add_absent, absent_defaults)

sink()

gff |>
  select(all_of(OUT_COLS)) |>
  format_tsv() |>
  writeLines(stdout(), sep = "")
