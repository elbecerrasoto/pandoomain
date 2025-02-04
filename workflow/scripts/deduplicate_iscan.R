#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(yaml)
})

argv <- commandArgs(trailingOnly = TRUE)

CONFIG <- argv[[1]]
ISCAN <- argv[[2]]

COL_NAMES <- read_yaml(CONFIG)$iscan_header

INCLUDE <- c(
  "pid", "start", "end",
  "len", "analysis", "interpro",
  "interpro_txt", "memberDB",
  "memberDB_txt"
)

# Main ----

iscan <- read_tsv(ISCAN,
  col_names = COL_NAMES,
  na = c("", "NA", "-"),
  show_col_types = FALSE
)

iscan <- iscan |>
  filter(recommended) |>
  distinct(pid, md5, memberDB, start, end, .keep_all = TRUE) |>
  arrange(pid, start, end) |>
  select(all_of(INCLUDE))

format_tsv(iscan) |>
  writeLines(stdout(), sep = "")
