#!/usr/bin/env Rscript

# Description ----

# INPUT: hmmer.tsv
# OUTPUT: neighbors.tsv to stdout

# It operates on the following columns
# genome, pid, query
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
DEBUG <- FALSE


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



# multicore is faster, but does not work on interactive session
if (interactive()) plan(multisession, workers = CORES) else plan(multicore, workers = CORES)


# output cols
SELECT <- c(
  "genome", "neid", "neoff",
  "order", "pid", "gene",
  "product", "start", "end",
  "strand", "frame", "locus_tag",
  "contig", "queries"
)


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

# Code ----

get_neighbors <- function(gff_path, n, subjects) {
  # Find all the neighborhoods on a given genome
  # A genome is specified by an existing gff file

  # Input:
  #
  #   gff_path: character
  #     A valid gff_path
  #
  #   n: integer
  #     At most +/- n neighbors to extract
  #
  #   subjects: tibble
  #     A table with target genes, it contains
  #     at least the following cols:
  #     genome, pid, query

  # Output:
  #   neighborhoods_on_genome: tibble

  gff <- read_gff(gff_path)

  # Add row numbers to extract neighborhood
  # A neighborhood is basically the context (+- rows) around a hit
  gff <- gff |>
    mutate(row = 1:nrow(gff)) |>
    relocate(row)

  igenome <- extract_genome(gff_path)

  # Filter by genome and reshape the subjects data to
  # expose all the queries that found an specific hit
  pid_queries <- subjects |>
    filter(genome == igenome) |>
    distinct(genome, pid, query) |>
    group_by(pid) |>
    summarize(queries = list(query))

  queries <- pid_queries$queries
  names(queries) <- pid_queries$pid

  hits <- gff |>
    filter(pid %in% pid_queries$pid)

  rows <- hits$row
  pids <- hits$pid

  # Check boundaries
  starts <- if_else(rows + n <= nrow(gff), rows + n, nrow(gff))
  ends <- if_else(rows - n >= 1, rows - n, 1)

  out <- vector(length = length(rows), mode = "list")

  # Iterate over all the hits found on a genome
  # Extracting the context of each hit
  for (i in seq_along(rows)) {
    # Which queries found current hit?
    matched_queries <- queries[[pids[[i]]]]

    s <- starts[i]
    e <- ends[i]
    icontig <- gff[rows[i], ]$contig

    # Extract the hit and its context
    # checking that they are on the same contig
    subgff <- gff[s:e, ] |>
      filter(contig == icontig)

    bottom <- min(subgff$row)
    center <- rows[i]
    top <- max(subgff$row)
    neiseqs <- get_neiseq(bottom, center, top)

    # Format the output
    outi <- subgff |>
      mutate(
        neid = i,
        neoff = neiseqs,
        queries = str_flatten(matched_queries, collapse = ",")
      )

    out[[i]] <- outi
  }

  # All neighborhoods found on a given genome
  bind_rows(out)
}

# Main ----

hmmer <- read_tsv(HMMER_FILE, show_col_types = FALSE)

genomes <- unique(hmmer$genome)
gffs_paths <- str_c(GENOMES_DIR, "/", genomes, "/", genomes, ".gff")

main <- partial(get_neighbors, n = N, subjects = hmmer)

if (DEBUG) {
  # A simpler map, earsier to debug with breakpoints
  done <- map(GFFS_PATHS, possibly(MAIN, tibble()))
} else {
  # Parallel map for full power
  done <- future_map(gffs_paths, possibly(main, tibble()))
}

neighbors <- bind_rows(done)
stopifnot("Empty Output." = nrow(neighbors) > 0)

# Printing to stdout does not work pretty well on list variables
neighbors |>
  select(all_of(SELECT)) |>
  print_tibble()
