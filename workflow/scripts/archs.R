#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
})


argv <- commandArgs(trailingOnly = TRUE)

# ISCAN <- argv[[1]]
# OUT <- argv[[2]]
# OUT_PIDFOCUS <- argv[[3]]
# OUT_CODE <- argv[[4]]

ISCAN <- "tests/results/iscan.tsv"
OUT <- "tests/results/archs.tsv"
OUT_PIDFOCUS <- "tests/results/archs_pidrow.tsv"
OUT_CODE <- "tests/results/archs_code.tsv"


get_arch_len <- function(arch) {
  str_split(arch, ",") |>
    map_int(length)
}

# Main ----

iscan <- read_tsv(ISCAN, show_col_types = FALSE)

iscan_summary <- iscan |>
  select(pid, memberDB, interpro, start, end, length, memberDB_txt) |>
  arrange(pid, start)

any(str_detect(iscan_summary$memberDB, ","))
any(str_detect(iscan_summary$memberDB, "\\|"))

iscan_summary$memberDB[str_detect(iscan_summary$memberDB, "\\|")]

str_flatten(c("hi", "hello"), collapse = "|")

stopifnot("Separator is used by a memberDB ID." = all(!str_detect(iscan_summary$memberDB, "\\|")))
stopifnot("Unexpeted NA on memberDB field." = all(!is.na(iscan_summary$memberDB)))

archs <- iscan_summary |>
  group_by(pid) |>
  summarize(
    archMEM = str_flatten(memberDB, collapse = "|"),
    archIPR = str_flatten(interpro[!is.na(interpro)], collapse = "|")
  )
