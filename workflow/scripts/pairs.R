#!/usr/bin/Rscript

library(glue)
library(stringr)
library(tidyverse)

args <- commandArgs(trailingOnly = TRUE)

# Globals -----------------------------------------------------------------

# Two genes
TARGETS <- c("WP_003243987.1", "WP_003243213.1")

# A distance is between 2 things
stopifnot(length(TARGETS) == 2)

# Input
CONFIG <- args[1]
HITS <- args[1]

CONFIG <- "tests/config.yaml"
HITS <- "tests/results/hits.tsv"

get_genome <- function(path) {
  str_extract(path, "GC[FA]_[0-9]+\\.[0-9]")
}

GENOME <- get_genome(HITS)

# Output
BASE <- "pairs"
OUT <- glue("{GENOME}_{BASE}.tsv")

graceful_exit <- function(assertion) {
  if (!assertion) {
    # write_tsv(tibble(), OUT)
    quit(status = 0)
  }
}


# Read the data
suppressMessages(hits <- read_tsv(HITS))
graceful_exit(nrow(hits) > 0)


# Calc --------------------------------------------------------------------


calc <- function(gene1, gene2) {
  stopifnot(is_tibble(gene1), is_tibble(gene2))
  stopifnot(gene1$order != gene2$order)
  stopifnot(gene1$contig == gene2$contig)


  first <- if (gene1$order < gene2$order) gene1 else gene2
  second <- if (gene1$order > gene2$order) gene1 else gene2

  distance <- second$start - first$end
  genes_inbet <- second$order - first$order

  tibble(
    genome = GENOME,
    distance = distance,
    genes_inbet = genes_inbet,
    contig = first$contig,
    query_1 = first$q_alias,
    pid_1 = first$pid,
    order_1 = first$order,
    start_1 = first$start,
    end_1 = first$end,
    strand_1 = first$strand,
    # locustag_1 = first$locus_tag,
    query_2 = second$q_alias,
    pid_2 = second$pid,
    order_2 = second$order,
    start_2 = second$start,
    end_2 = second$end,
    strand_2 = second$strand,
    # locustag_2 = second$locus_tag,
  )
}


# Main --------------------------------------------------------------------


hits <- hits |>
  filter(query %in% TARGETS)

# Query to factor
# Used on counting pairs
hits <- hits |>
  mutate(
    query = as_factor(query),
    query = `levels<-`(query, TARGETS)
  )

CONTIGS <- hits |>
  pull(contig) |>
  unique()

# Calculate the number of distance operations
count_pairs <- function(hits) {
  n <- 0

  contig_query <- hits |>
    count(contig, query, .drop = FALSE)

  for (contig in CONTIGS) {
    x <- contig_query |>
      filter(contig == {{ contig }}) |>
      pull(n) |>
      reduce(`*`)
    n <- n + x
  }
  n
}

N_PAIRS <- count_pairs(hits)
graceful_exit(N_PAIRS > 0)

results <- vector(mode = "list", length = N_PAIRS)

i <- 0
for (contig in CONTIGS) {
  same_contig <- hits |>
    filter(contig == {{ contig }}) %>%
    split(.$query)

  if (length(same_contig) != 2) next

  genes_q1 <- same_contig[[1]]
  genes_q2 <- same_contig[[2]]

  for (g1_idx in seq_len(nrow(genes_q1))) {
    for (g2_idx in seq_len(nrow(genes_q2))) {
      i <- i + 1
      gene1 <- genes_q1[g1_idx, ]
      gene2 <- genes_q2[g2_idx, ]
      results[[i]] <- calc(gene1, gene2)
    }
  }
}

stopifnot(N_PAIRS == i)

do.call(bind_rows, results) |>
  write_tsv(OUT)
