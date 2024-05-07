#!/usr/bin/Rscript

suppressPackageStartupMessages({
  library(tidyverse)
})

args <- commandArgs(trailingOnly = TRUE)

IN <- args[[1]] # "tests/results/blasts.tsv"
blasts <- read_tsv(IN)
headers <- blasts$stitle
seqs <- blasts$full_sseq

for (i in seq_along(headers)) {
  cat(">", headers[[i]], "\n", seqs[[i]], "\n", sep = "")
}
