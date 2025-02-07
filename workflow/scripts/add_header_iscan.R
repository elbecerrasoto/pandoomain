#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(yaml)
})

argv <- commandArgs(trailingOnly = TRUE)

ISCAN <- argv[[1]]

COL_NAMES <-
  c(
    "pid",
    "md5",
    "length",
    "analysis",
    "memberDB",
    "memberDB_txt",
    "start",
    "end",
    "score",
    "recommended",
    "date",
    "interpro",
    "interpro_txt",
    "GO",
    "residue"
  )
INCLUDE <- c(
  "pid", "start", "end",
  "length", "analysis", "interpro",
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
