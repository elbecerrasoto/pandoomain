#!/usr/bin/env Rscript

library(tidyverse)
library(stringr)

argv <- commandArgs(trailingOnly = TRUE)
MAX <- as.integer(argv[1])
IN <- argv[2]
# MAX <- 64
# IN <- "clean_bacillota.tsv"

meta <- read_tsv(IN, show_col_types = FALSE)

sample_n_all <- function(x, n) {
  N <- nrow(x)
  if (n <= N) {
    return(sample_n(x, n, replace = FALSE))
  } else {
    return(x)
  }
}

meta <- meta |>
  group_by(genus) |>
  group_modify(~ sample_n_all(.x, MAX)) |>
  ungroup() |>
  relocate(genus, .after = org)

meta |>
  format_tsv() |>
  writeLines(stdout(), sep = "")
