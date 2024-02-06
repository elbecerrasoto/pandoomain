#!/usr/bin/Rscript

args <- commandArgs(trailingOnly = TRUE)

IN <- "tests/results/blasts.tsv"
OUT <- "tests/results/blasts_hits.tsv"
MIN_BSCORE <- 100
MIN_COV <- 70

library(tidyverse)

read_tsv(IN, col_names = T) %>%
    filter(bitscore >= MIN_BSCORE, qcovhsp >= MIN_COV, scovhsp >= MIN_COV) %>%
    write_tsv(OUT)
