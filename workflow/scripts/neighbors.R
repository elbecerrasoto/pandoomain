#!/usr/bin/Rscript


suppressPackageStartupMessages({
  library(tidyverse)
  library(rlang) # warnings utils
  library(segmenTools)
  library(glue)
})


# Globals ----

ARGV <- commandArgs(trailingOnly = TRUE)
GFF <- ARGV[[1]]
# GFF <- "tests/results/genomes/GCF_001286845.1/GCF_001286845.1.gff"

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
  "product",
)

GENOME_RE <- "GC[FA]_[0-9]+\\.[0-9]"


# Helpers ----


read_gff <- function(path) {
  genome <- str_extract(path, GENOME_RE)

  # segmenTools is not well behaved
  # so it sends messages to stdout
  # that should be on stderr
  sink(stderr(), type = "output")

  gff <- segmenTools::gff2tab(path) |>
    tibble() |>
    filter(feature == "CDS") |> # only CDS
    select_if({
      \(x) !(all(is.na(x)) | all(x == ""))
    }) # exclude empty cols

  sink()

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

  # add genome, and rename to consistent names across the pipeline
  gff <- gff |>
    rename(pid = protein_id, contig = seqname) |>
    mutate(genome = genome)

  # fix missing columns (if any)

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

  # return
  gff
}


# Helpers ----
