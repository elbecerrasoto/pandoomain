#!/usr/bin/env Rscript

# Description ----

# INPUT: hmmer.tsv
# OUTPUT: neighbors.tsv to stdout

# It operates on the following columns
# genome, pid, queries
# Any input table with those columns will do

# Globals ----

suppressPackageStartupMessages({
  library(tidyverse)
  library(rlang) # warnings utils
  library(segmenTools)
  library(glue)
  library(furrr)
})


ARGV <- commandArgs(trailingOnly = TRUE)


if (!interactive()) {
  CORES <- as.integer(ARGV[[1]])
  N <- as.integer(ARGV[[2]])
  GENOMES_DIR <- ARGV[[3]]
  HMMER_FILE <- ARGV[[4]]
} else {
  CORES <- 12L
  N <- 8L
  GENOMES_DIR <- "tests/results/genomes"
  HMMER_FILE <- "tests/results/hmmer.tsv"
}


HMMER <- read_tsv(HMMER_FILE, show_col_types = FALSE)
GENOMES <- unique(HMMER$genome)
GFFS_PATHS <- str_c(GENOMES_DIR, "/", GENOMES, "/", GENOMES, ".gff")

# multicore is faster, but does not work on interactive session
if (interactive()) plan(multisession, workers = CORES) else plan(multicore, workers = CORES)


SELECT <- c("genome", "nei", "neioff", "order", "pid", "gene", "product", "start", "end", "strand", "frame", "locus_tag", "contig", "queries")


# Helpers ----


extract_genome <- function(path) {
  GENOME_RE <- "GC[FA]_[0-9]+\\.[0-9]"
  str_extract(path, GENOME_RE)
}


read_gff <- function(path) {
  OUT_COLS <- c(
    "genome",
    "pid",
    "gene",
    "order",
    "start",
    "end",
    "contig",
    "strand",
    "locus_tag",
    "product"
  )

  igenome <- extract_genome(path)

  # segmenTools is not well behaved
  # it sends messages to stdout
  sink("/dev/null", type = "output")
  gff <- segmenTools::gff2tab(path)
  sink()

  gff <- gff |>
    tibble() |>
    filter(feature == "CDS") |> # only CDS
    select_if({
      \(x) !(all(is.na(x)) | all(x == ""))
    }) # exclude empty cols


  # Remove pseudogenes
  if ("pseudo" %in% names(gff)) {
    gff <- gff |>
      filter(is.na(pseudo))
  }

  # Definition of neighbor
  # same contig, order by start position
  gff <- gff |>
    group_by(seqname) |>
    arrange(start) |>
    mutate(order = seq_along(start)) |>
    relocate(order) |>
    ungroup()

  # Sort to spot patterns
  gff <- gff |>
    arrange(seqname, order)

  # add genome, and rename to consistent names across the pipeline
  gff <- gff |>
    rename(pid = protein_id, contig = seqname) |>
    mutate(genome = igenome)

  # fix missing columns (if any)

  present <- OUT_COLS %in% names(gff)
  absent <- OUT_COLS[!present]

  msg <- glue("The following columns were not present:\n{str_flatten(absent, collapse = ' ')}\nOn the file:\n{path}")

  if (!all(present)) {
    warn(msg)
  }

  # add missing features
  absent_defaults <- setNames(as.list(rep(NA, length(absent))), absent)
  add_absent <- partial(add_column, .data = gff)

  gff <- do.call(add_absent, absent_defaults)

  # return
  gff
}


get_neiseq <- function(bottom, center, top) {
  ll <- center - bottom # length left
  lr <- top - center # length right

  left <- if (ll > 0) -ll:-1 else NULL
  right <- if (lr > 0) 1:lr else NULL

  c(left, 0L, right)
}


print_tibble <- function(tib) {
  format_tsv(tib) |>
    writeLines(stdout(), sep = "")
}

queries2onehot <- function(neighbors) {
  queries_onehot <- neighbors |>
    group_by(genome, pid) |>
    reframe(query = unlist(queries)) |>
    mutate(presence = TRUE) |>
    distinct() |>
    pivot_wider(
      names_from = query,
      values_from = presence,
      values_fill = FALSE,
      names_sort = TRUE
    )

  out <- left_join(queries_onehot, neighbors, join_by(genome, pid),
    relationship = "many-to-many"
  ) |>
    relocate(all_of(SELECT)) |>
    arrange(genome, nei, neioff)

  out
}

# Code ----


process_gff <- function(gff, hmmer) {
  queries <- hmmer$queries
  names(queries) <- hmmer$pid

  pids <- unique(hmmer$pid)

  hits <- gff |>
    filter(pid %in% pids)

  rows <- hits$row
  pids <- hits$pid

  starts <- if_else(rows + N <= nrow(gff), rows + N, nrow(gff))
  ends <- if_else(rows - N >= 1, rows - N, 1)

  out <- vector(length = length(rows), mode = "list")
  for (i in seq_along(rows)) {
    matched_queries <- queries[pids[i]]

    s <- starts[i]
    e <- ends[i]
    icontig <- gff[rows[i], ]$contig

    subgff <- gff[s:e, ] |>
      filter(contig == icontig)

    bottom <- min(subgff$row)
    center <- rows[i]
    top <- max(subgff$row)
    neiseqs <- get_neiseq(bottom, center, top)

    outi <- subgff |>
      mutate(
        nei = i,
        neioff = neiseqs,
        queries = matched_queries
      )

    out[[i]] <- outi
  }

  bind_rows(out)
}


get_neighbors <- function(gff_path) {
  gff <- read_gff(gff_path)
  gff <- gff |>
    mutate(row = 1:nrow(gff)) |>
    relocate(row)

  igenome <- extract_genome(gff_path)

  hmmer <- HMMER |>
    filter(genome == igenome) |>
    distinct(genome, pid, query) |>
    group_by(pid) |>
    summarize(queries = list(query))

  process_gff(gff, hmmer) |>
    select(all_of(SELECT))
}


MAIN <- function(gff_path) {
  tryCatch(
    error = function(cnd) {
      msg <- glue("Call: get_neignbors({gff_path})\n Error: {cnd}")
      stop(msg)
    },
    {
      get_neighbors(gff_path)
    }
  )
}


done <- future_map(GFFS_PATHS, possibly(MAIN, tibble()))

neighbors <- bind_rows(done)

neighbors |>
  queries2onehot() |>
  print_tibble()
