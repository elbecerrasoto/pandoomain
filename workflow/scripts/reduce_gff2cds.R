#!/usr/bin/Rscript

# print to stdout the result of the program
# sink everything else
sink(stderr(), type = "output")

library(tidyverse)
library(rlang) # warnings utils
library(segmenTools)
library(glue)

args <- commandArgs(trailingOnly = TRUE)


# Globals ----


# GFF <- "tests/results/genomes/GCF_001286845.1/GCF_001286845.1.gff"
GFF <- args[1]

OUT_COLS <- c(
  "genome",
  "pid",
  "gene",
  "order",
  "start",
  "end",
  "contig",
  "strand",
  "locus_tag",
  "product"
)

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
  sink(stderr(), type = "output")

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

  # sort to spot patterns
  # contig then order inside contig
  gff <- gff |>
    arrange(seqname, order)

  gff
}


# Code ----


gff <- read_gff(GFF) |>
  mutate(genome = GENOME, pid = protein_id, contig = seqname) |>
  select(any_of(OUT_COLS))

present <- OUT_COLS %in% names(gff)
if (!all(present)) {
  absent <- OUT_COLS[!present]
  warn(glue("The following columns were not present:\n{absent}\nOn the file:\n{GFF}"))
}

sink()

gff |>
  format_tsv() |>
  writeLines(stdout(), sep = "")
