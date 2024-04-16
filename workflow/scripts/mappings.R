library(yaml)
library(tidyverse)

args <- commandArgs(trailingOnly = T)

# Globals ----

CONFIG <- args[1]
ISCAN <- args[2]
BLASTS_PIDS <- args[3]

CONFIG <- "tests/config.yaml"
ISCAN <- "tests/results/iscan.tsv"
BLASTS <- "tests/results/blasts.tsv"

# Read ----

config <- read_yaml(CONFIG)

filters <- config$filtering_domains
aliases <- config$query_aliases

pids2filter <- names(filters)
pids2alias <- names(aliases)

iscan <- read_tsv(ISCAN, na = c("-", "NA", ""))

blasts <- read_tsv(BLASTS)

# Helpers ----

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

# Main ----

# Mappings
# queries 1->M pids M->M domains
# queries 1->M pids M->M genomes

# queries 1->M pids
q2pids <- blasts |>
  rename(query = qseqid) |>
  group_by(query) |>
  reframe(pid = unique(sseqid))

stopifnot(is_tbl_NA_free(q2pids))


if (F) {
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
}
