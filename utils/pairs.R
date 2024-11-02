#!/usr/bin/Rscript

suppressPackageStartupMessages({
  library(yaml)
  library(rlang)
  library(stringr)
  library(tidyverse)
  library(furrr)
})


args <- commandArgs(trailingOnly = TRUE)


# Globals ----


CONFIG <- args[1]
HITS <- args[2]
GPQ <- args[3]
HITS_QUERY <- args[4]
CORES <- as.numeric(args[5])

## CONFIG <- "tests/config.yaml"
## HITS <- "tests/results/hits.tsv"
## GPQ <- "tests/results/genome_pid_query.tsv"
## HITS_QUERY <- "tests/results/hits_query.tsv"

# Returns NULL on missing
TARGETS <- read_yaml(CONFIG)$pair


if (is.null(TARGETS)) {
  writeLines("", stdout(), sep = "")
  quit(save = "no", status = 0)
}

# A distance is between 2 things
stopifnot("A distance is between 2 things. Ill-formed pair." = length(TARGETS) == 2)


hits <- read_tsv(HITS, show_col_types = FALSE)
gpq <- read_tsv(GPQ, show_col_types = FALSE)

plan(multisession, workers = CORES)

# Calc ----


calc <- function(gene1, gene2) {
  stopifnot(is_tibble(gene1), is_tibble(gene2))
  stopifnot(gene1$order != gene2$order)
  stopifnot(gene1$contig == gene2$contig)


  first <- if (gene1$order < gene2$order) gene1 else gene2
  second <- if (gene1$order > gene2$order) gene1 else gene2

  distance <- second$start - first$end
  genes_inbet <- second$order - first$order

  tibble(
    genome = first$genome,
    distance = distance,
    genes_inbet = genes_inbet,
    contig = first$contig,
    query_1 = first$query_description,
    pid_1 = first$pid,
    order_1 = first$order,
    start_1 = first$start,
    end_1 = first$end,
    strand_1 = first$strand,
    locustag_1 = first$locus_tag,
    query_2 = second$query_description,
    pid_2 = second$pid,
    order_2 = second$order,
    start_2 = second$start,
    end_2 = second$end,
    strand_2 = second$strand,
    locustag_2 = second$locus_tag,
  )
}


# Main ----

# Add domain information
hits <- hits |>
  left_join(gpq, join_by(pid, genome))

hits <- hits |>
  relocate(query_description, .after = genome)

hits |>
  write_tsv(HITS_QUERY)

# Filter to pairs
hits_filtered <- hits |>
  filter(query %in% TARGETS)

stopifnot("Not enough hits to find pairs." = nrow(hits) > 1)

# Query to factor
# Used on counting pairs
hits_filtered <- hits_filtered |>
  mutate(
    query = as_factor(query),
    query = `levels<-`(query, TARGETS)
  )


find_pairs_per_genome <- function(hits) {
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
  if (N_PAIRS == 0) {
    return(tibble())
  }

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

  do.call(bind_rows, results)
}


find_pairs_per_genome <- possibly(
  find_pairs_per_genome,
  tibble()
)

pairs <- hits_filtered |>
  group_by(genome) |>
  group_split() |>
  future_map(find_pairs_per_genome) |>
  do.call(bind_rows, args = _)


pairs |>
  format_tsv() |>
  writeLines(stdout(), sep = "")
