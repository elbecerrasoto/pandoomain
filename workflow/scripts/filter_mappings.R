#!/usr/bin/Rscript

# Filter blasts by absence/presence of interpro domains

library(yaml)
library(tidyverse)

args <- commandArgs(trailingOnly = TRUE)


# Globals ----


CONFIG <- args[1]
MAPPINGS <- args[2]

CONFIG <- "tests/config.yaml"
MAPPINGS <- "tests/results/mappings_raw.tsv"

FILTER <- read_yaml(CONFIG)$filtering_domains

mappings <- read_tsv(MAPPINGS)


# Helpers ----


check_domains <- function(query, domains, domains_to_check) {
  # Returns a boolean per query
  # TRUE if it is to kept, FALSE otherwise
  # to be used inside a tidyverse filter()
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


# Main ----


# Filter mappings
mappings_filtered <- mappings |>
  group_by(q_alias, query, pid, genome) |>
  summarise(domains = list(domain)) |>
  filter(check_domains(query, domains, FILTER))

print(mappings_filtered)
