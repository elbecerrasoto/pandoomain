#!/usr/bin/Rscript

suppressPackageStartupMessages({
  library(tidyverse)
})

args <- commandArgs(trailingOnly = TRUE)

IN <- args[1] # "tests/results/blasts.tsv"

blasts <- read_tsv(IN)

unique_proteins <- blasts |>
  distinct(stitle, .keep_all = T)

headers <- unique_proteins |> pull(stitle)
seqs <- unique_proteins |> pull(full_sseq)

for (i in seq_along(headers)) {
  cat(">", headers[i], "\n", seqs[i], "\n", sep = "")
}
