#!/usr/bin/Rscript

library(yaml)
library(magrittr)
library(tidyverse)


args <- commandArgs(trailingOnly = T)


# Globals ----


CONFIG <- args[1]
ISCAN <- args[2]
BLASTS_PIDS <- args[3]

CONFIG <- "tests/config.yaml"
ISCAN <- "tests/results/iscan.tsv"
BLASTS <- "tests/results/blasts.tsv"


# Helpers ----


is_tbl_NA_free <- function(tbl) {
  tbl |>
    map_lgl(\(x) all(!is.na(x))) |>
    all()
}

stop_on_NA <- function(tbl) stopifnot(is_tbl_NA_free(tbl))


# Read Data ----


config <- read_yaml(CONFIG)

filtersL <- config$filtering_domains
aliasesL <- config$query_aliases

iscan <- read_tsv(ISCAN, na = c("-", "NA", ""))

blasts <- read_tsv(BLASTS) |>
  rename(
    query = qseqid,
    pid = sseqid
  )


# Mappings ----


# 1->M one to many
# M->M many to many

# The output table contains the following relations
# aliases 1->1 queries 1->M pids M->M domains
# aliases 1->1 queries 1->M pids M->M genomes


# setup aliases 1->1 queries
queries <- unique(blasts$query)

assign_alias <- function(query, alias_dict) {
  alias <- alias_dict[[query]]
  present <- !is.null(alias)
  ifelse(present, alias, query)
}

aliases <- queries |>
  map_chr(assign_alias, alias_dict = aliasesL)

# aliases 1->1 queries
alias2query <- tibble(
  q_alias = aliases,
  query = queries
) %T>%
  stop_on_NA()


# queries 1->M pids
query2pids <- blasts |>
  group_by(query) |>
  reframe(pid = unique(pid)) %T>%
  stop_on_NA()


# pids M->M domains
pid2domains <- iscan |>
  group_by(pid) |>
  reframe(domain = unique(interpro[!is.na(interpro)])) %T>%
  stop_on_NA()


# pids M->M genomes
pid2genomes <- blasts |>
  group_by(pid) |>
  reframe(genome = unique(genome)) %T>%
  stop_on_NA()


# Join and Output ----


mappings <- alias2query |>
  left_join(query2pids, join_by(query)) %T>%
  stop_on_NA() |>
  left_join(pid2domains, join_by(pid),
    relationship = "many-to-many"
  ) |>
  left_join(pid2genomes, join_by(pid),
    relationship = "many-to-many"
  )

mappings |>
  format_tsv() |>
  writeLines(stdout(), sep = "")
