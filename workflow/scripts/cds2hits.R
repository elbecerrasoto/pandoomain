#!/usr/bin/Rscript

sM <- suppressMessages

sM(library(tidyverse))
sM(library(rlang))
library(segmenTools)
library(glue)

args <- commandArgs(trailingOnly = TRUE)


# Globals ----

PIDS <- args[1] # "tests/results/blasts_pids.txt"
GFF <- args[2] # "tests/results/genomes/GCF_000699465.1/GCF_000699465.1.gff"

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
  sink(stderr(), type = "output")

  gff <- segmenTools::gff2tab(GFF) |>
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
    relocate(order)

  sink()
  gff
}


# Code ----

pids <- sM(read_tsv(PIDS, col_names = "pid"))
gff <- read_gff(GFF)

hits <- inner_join(pids, gff, join_by(pid == protein_id)) |>
  mutate(genome = GENOME, contig = seqname) |>
  select(any_of(OUT_COLS))


present <- OUT_COLS %in% names(hits)
if (!all(present)) {
  absent <- OUT_COLS[!present]
  warn(glue("The following columns were not present:\n{absent}"))
}

hits |>
  format_tsv() |>
  writeLines(stdout())
