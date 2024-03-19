#!/usr/bin/Rscript
library(tidyverse)
library(stringr)
args <- commandArgs(trailingOnly = TRUE)


# Globals -----------------------------------------------------------------


OUT_BLASTS <- "blasts_filtered.tsv"
OUT_MAPPINGS <- "mappings_filtered.tsv"

# Filter blasts by domain
BLASTS <- "results/blasts.tsv"
MAPPINGS <- "mappings.tsv"

# YwqJ
# LXG - IPR006829 TO_SEARCH
# PT-TG - IPR027797
# YwqJ-like - IPR025968 TO_SEARCH

# YwqL
# Endonuclease-V - IPR007581 TO_SEARCH

FILTER <- list(
  WP_003243987.1 = c("IPR006829", "IPR025968"),
  WP_003243213.1 = c("IPR007581")
)


# Reading Data ------------------------------------------------------------


blasts <- read_tsv(BLASTS) # only to filter it
mappings <- read_tsv(MAPPINGS) # operate on this table

# Helpers -----------------------------------------------------------------




# vectorized boolean function
# to be used on dplyr::filter steps
# tbl var | l = n | query: chr
# tbl var | l = n | domains: list chr
# domains_to_check: list chr
# OUT | l = n | lgl


check_domains <- function(query, domains, domains_to_check) {
  n <- length(domains)
  filter_lgl <- rep(TRUE, n) # default value

  if (length(domains_to_check) == 0) {
    return(filter_lgl)
  } else {
    for (i in seq_along(domains)) {
      for (Q in names(domains_to_check)) {
        if (query[i] == Q) {
          filter_lgl[i] <- domains_to_check[[Q]] %in% domains[[i]] |>
            all()

          break()
        }
      }
    }
  }
  filter_lgl
}


# Policy ------------------------------------------------------------------

# Filter mappings
mappings_filtered <- mappings |>
  group_by(q_alias, query, pid) |>
  summarise(domains = list(domain)) |>
  filter(check_domains(query, domains, FILTER))


# TODO: Use a single string with a sep like ";"
# instead of a list

mappings_filtered |>
  group_by(q_alias, query, pid) |>
  reframe(domain = unlist(domains)) |>
  arrange(query, pid, domain) |>
  group_by(q_alias, query, pid) |>
  summarise(domains = str_flatten(domain, collapse = ";")) |>
  write_tsv(OUT_MAPPINGS)


# Filter blasts
blasts_filtered <- semi_join(
  blasts, mappings_filtered,
  join_by(sseqid == pid)
)

blasts_filtered |>
  write_tsv(OUT_BLASTS)
