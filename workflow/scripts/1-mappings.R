#!/usr/bin/Rscript

sM <- suppressMessages
sM(library(tidyverse))

args <- commandArgs(trailingOnly = TRUE)

BLASTS <- "tests/results/blasts.tsv"
ISCAN <- "tests/results/"

QUERIES <- c("WP_003243987.1", "WP_003243213.1")
QUERIES_ALIASES <- c("YwqJ", "YwqL") |>
  `names<-`(QUERIES)


# Reading -----------------------------------------------------------------


blasts <- read_tsv(BLASTS)
iscan <- read_tsv(ISCAN, na = c("-", "NA", ""))


# Helpers -----------------------------------------------------------------



is_tbl_NA_free <- function(tbl) {
  tbl |>
    map_lgl(\(x) all(!is.na(x))) |>
    all()
}


switch_vectorized <- function(v_chr, switch_list) {
  f <- function(v_chr) {
    do.call(
      switch,
      c(v_chr, switch_list, NA)
    )
  }
  map_chr(v_chr, f)
}

length(paste(letters))
str_flatten(letters, collapse = ";")


# Code --------------------------------------------------------------------


# Mappings
# qs -> pids -> doms


# Map each query to pid (is a 1-to-many mapping)
q2pids <- blasts |>
  group_by(qseqid) |>
  reframe(pid = unique(sseqid)) |>
  rename(query = qseqid)

stopifnot(is_tbl_NA_free(q2pids))

# Add the aliases
q2pids <- q2pids |>
  mutate(q_alias = switch_vectorized(
    query,
    map(QUERIES_ALIASES, \(x) x)
  )) |>
  relocate(q_alias)


q2pids

blasts
blasts |>
  group_by(sseqid) |>
  summarise(genomes = str_flatten(unique(genome), collapse = ";"))





# Map each pid to domains (is a 1-to-many mapping)
pid2doms <- iscan |>
  group_by(protein) |>
  reframe(domain = unique(interpro[!is.na(interpro)])) |>
  rename(pid = protein)

stopifnot(is_tbl_NA_free(pid2doms))


# Join both tables
q2pids2domains <- left_join(q2pids, pid2doms)

q2pids2domains |>
  write_tsv(OUT)
