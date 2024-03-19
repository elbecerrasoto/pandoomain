#!/usr/bin/Rscript

library(glue)
library(stringr)
suppressMessages(library(tidyverse))
library(segmenTools)

args <- commandArgs(trailingOnly = TRUE)

# Globals -----------------------------------------------------------------

# Input
GFF <- args[[1]] # "results/genomes/GCF_000699465.1/GCF_000699465.1.gff"
MAPPINGS <- "mappings_filtered.tsv"


get_genome <- function(path) {
  str_extract(path, "GC[FA]_[0-9]+\\.[0-9]")
}


GENOME <- get_genome(GFF)


# Output
BASE <- "hits"
OUT <- glue("{GENOME}_{BASE}.tsv")

OUT_COLS <- c(
  "genome",
  "pid",
  "gene",
  "q_alias",
  "order",
  "start",
  "end",
  "contig",
  "strand",
  "locus_tag",
  "query",
  "domains",
  "product"
)


# Read the Data -----------------------------------------------------------


suppressMessages(mappings <- read_tsv(MAPPINGS))

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


# definition of neighbor
# same contig, order by start position
gff <- gff |>
  group_by(seqname) |>
  arrange(start) |>
  mutate(order = seq_along(start)) |>
  relocate(order)


# Policy ------------------------------------------------------------------


hits <- inner_join(mappings, gff, join_by(pid == protein_id)) |>
  mutate(genome = GENOME, contig = seqname) |>
  select(any_of(OUT_COLS)) # any and emit a warning

# TODO warning here

N_HITS <- nrow(hits)
if (N_HITS == 0) {
  cat("\n\nNothing to be DONE.\n")
  cat(glue("Genome: {GENOME} has no hits.\n\n\n"))
  quit(status = 0)
} else {
  cat(glue("\n\nGenome: {GENOME} has {N_HITS} hits.\n"))
  cat(glue("\n\nWriting {OUT}.\n\n\n"))
  hits |>
    write_tsv(OUT)
}
