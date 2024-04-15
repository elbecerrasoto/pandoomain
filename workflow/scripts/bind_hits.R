#!/usr/bin/Rscript

sM <- suppressMessages
sM(library(tidyverse))
sM(library(furrr))

args <- commandArgs(trailingOnly = TRUE)

CORES <- args[1]
GFFS <- args[2:length(args)]


plan(multisession, workers = CORES)

sM(
  all_L <- GFFS |>
    future_map(read_tsv)
)


all <- do.call(bind_rows, all_L)


all |>
  format_tsv() |>
  writeLines(stdout())
