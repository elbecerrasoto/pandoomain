#!/usr/bin/env Rscript

# Join Manually
# genomes_metadata.tsv & taxallnomy_lin_name.tsv
# by taxid
# why? to only use the relevant part of the table taxallnomy table.

library(tidyverse)

TAXID_ALL <- "tests/results/.taxallnomy_lin_name.txt"
TAXID_GENOMES <- "tests/results/genomes_metadata.tsv"

TREE <- "tests/results/taxallnomy_lin_name.tsv"

NAMES <- c(
  "tax_id", "superkingdom", "Kin", "sbKin",
  "spPhy", "phylum", "sbPhy", "inPhy", "spCla",
  "class", "sbCla", "inCla", "Coh", "sbCoh",
  "spOrd", "order", "sbOrd", "inOrd", "prOrd",
  "spFam", "family", "sbFam", "Tri", "sbTri",
  "genus", "sbGen", "Sec", "sbSec", "Ser",
  "sbSer", "Sgr", "sbSgr", "species", "Fsp",
  "sbSpe", "Var", "sbVar", "For", "Srg",
  "Srt", "Str", "Iso"
)


# styler: off
genomes    <- read_tsv(TAXID_GENOMES) |>
  select(genome, tax_id)
taxallnomy <- read_tsv(TAXID_ALL, col_names = "tax_id")

taxid_all     <-     taxallnomy$tax_id
taxid_genomes <- unique(genomes$tax_id)
# styler: on

rows <- sort(which(taxid_all %in% taxid_genomes))

# subset the taxallnomy table
# to only relevant entries

tree <- read_tsv(TREE, col_names = NAMES)
relevant <- tree[rows, ]
rm(tree)

genomes |>
  left_join(relevant, join_by(tax_id)) |>
  format_tsv() |>
  writeLines(stdout(), sep = "")
