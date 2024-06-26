#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(furrr)
})


args <- commandArgs(trailingOnly = TRUE)

CORES <- args[1]
INPUTS <- args[2:length(args)]


plan(multisession, workers = CORES)

read_typed <- partial(read_tsv, col_types = "ccciiicccc")


all_L <- INPUTS |>
  future_map(read_typed)


all <- do.call(bind_rows, all_L)


all |>
  format_tsv() |>
  writeLines(stdout())
