#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(furrr)
})


args <- commandArgs(trailingOnly = TRUE)

CORES <- args[1]
INPUTS <- args[2:length(args)]


plan(multisession, workers = CORES)


all_L <- INPUTS |>
  future_map(read_tsv)


all <- do.call(bind_rows, all_L)


all |>
  format_tsv() |>
  writeLines(stdout())
