#!/usr/bin/Rscript

args <- commandArgs(trailingOnly = TRUE)

OUT <- args[1] # "tests/results/blasts.tsv"
DATA_DIR <- args[2] # "tests/results/genomes"
GENOMES_TXT <- args[3] # "tests/genomes.txt"
FIELDS_TXT <- args[4] # "config/blast_fields.txt"
CORES <- as.integer(args[5]) # 12
DEBUG <- as.logical(args[6]) # Suppress messages (stderr)

GENOME_REGEX <- "\\w+_\\d+\\.\\d"
COL <- "genome"

if (!DEBUG) {
  null <- file(nullfile(), open = "w")
  sink(null, type = "message")
}

library(tidyverse)
library(stringr)
library(furrr)


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
  future_map(possibly(\(x) read_tsv(x, col_names = fields), tibble()))

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


if (!DEBUG) {
  sink()
}
