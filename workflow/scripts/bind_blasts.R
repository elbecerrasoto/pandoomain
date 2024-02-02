#!/usr/bin/Rscript

SUPRESS <- T # Suppress messages (stderr)

if (SUPRESS) {
  null <- file(nullfile(), open = "w")
  sink(null, type = "message")
}

library(tidyverse)
library(stringr)
library(furrr)

args <- commandArgs(trailingOnly = TRUE)

OUT <- "tests/results/blasts.tsv" # args[1]
DATA_DIR <- "tests/results/genomes" # args[2]
GENOMES_TXT <- "tests/genomes.txt" # args[3]
FIELDS_TXT <- "config/blast_fields.txt" # args[4]
CORES <- 12 # args[5]
GENOME_REGEX <- "\\w+_\\d+\\.\\d"
COL <- "genome"

plan(multisession, workers = CORES)

add_newcol_from_iname <- function(i, l, col = COL) {
  df <- l[[i]]
  value <- names(l)[[i]]
  df %>%
    mutate("{col}" := value) %>%
    relocate({{ col }})
}

is_empty_tibble <- function(df) {
  nrow(df) == 0L
}

# Read blast tables -------------------------------------------------------

# drop first entry, it contains '6' specifying the tabular format
fields <- read_tsv(FIELDS_TXT, col_names = F, comment = "#")[[1]][-1]

genomes <- read_tsv(GENOMES_TXT, col_names = F, comment = "#")[[1]] %>%
  subset(str_detect(., GENOME_REGEX)) # drop ill-formed assembly ids

blasts <- str_c(DATA_DIR, "/", genomes, "/", genomes, ".tsv") %>%
  future_map(read_tsv, col_names = fields)

blasts <- str_c(DATA_DIR, "/", genomes, "/", genomes, ".tsv") %>%
  future_map(read_tsv, col_names = fields)

names(blasts) <- genomes

# Remove empty tables
blasts <- blasts %>%
  map_lgl(is_empty_tibble) %>%
  `!`() %>%
  subset(blasts, .)

# Add genome col and join all ---------------------------------------------

blasts %>%
  future_map(seq_along(.), add_newcol_from_iname, l = .) %>%
  reduce(bind_rows) %>%
  write_tsv(OUT)


if (SUPRESS) {
  sink()
}
