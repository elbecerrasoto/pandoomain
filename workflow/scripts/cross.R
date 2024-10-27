#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(tidyverse)
})

# Join taxallnomy_lin_name.tsv and genomes_metadata.tsv
# by tax_id

argv <- commandArgs(trailingOnly = TRUE)

TAXID_ALL <- argv[[1]]
TAXID_GENOMES <- argv[[2]]

# TAXID_ALL <- "tests/results/taxallnomy_lin_name.tsv"
# TAXID_GENOMES <- "tests/results/genomes_metadata.tsv"

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

taxallnomy <- fread(TAXID_ALL)
names(taxallnomy) <- NAMES

genomes <- fread(TAXID_GENOMES) |>
  select(genome, tax_id)

genomes |>
  left_join(taxallnomy, join_by(tax_id)) |>
  format_tsv() |>
  writeLines(stdout(), sep = "")
