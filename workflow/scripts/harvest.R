#!/usr/bin/env Rscript

# Globals ----

suppressPackageStartupMessages({
  library(tidyverse)
  library(furrr)
  library(seqinr)
  library(fs)
})

argv <- commandArgs(trailingOnly = TRUE)


DB <- argv[[1]]
CORES <- as.integer(argv[[2]])
IN <- argv[[3]]
OUT_DIR <- argv[[4]]

# DB <- "tests/results/genomes"
# IN <- "tests/results/hmmer.tsv"
# OUT_DIR <- "tests/results/domains_faas"

plan(multicore, workers = CORES)

# Helpers ----

get_headers <- function(faa) {
  map_chr(faa, \(s) attr(s, "Annot"))
}

write_query <- function(query_tib) {
  query_tib <- distinct(query_tib, pid, .keep_all = TRUE)
  query <- unique(query_tib$query)
  txt <- unique(query_tib$query_txt)

  stopifnot(
    length(query) == 1,
    length(txt) == 1
  )

  OUT_FAA <- paste0(OUT_DIR, "/", query, "_", txt, ".faa")
  unlink(OUT_FAA)


  write_genome <- function(genome_tib) {
    genome <- unique(genome_tib$genome)
    in_genome <- paste0(DB, "/", genome, "/", genome, ".faa")
    pids <- unique(genome_tib$pid)

    stopifnot(length(genome) == 1)

    faa <- read.fasta(in_genome, seqtype = "AA", strip.desc = TRUE)
    faa <- faa[names(faa) %in% pids]

    write.fasta(faa, get_headers(faa),
      OUT_FAA,
      open = "a",
      nbchar = 80
    )
  }


  Lgenomes <- query_tib %>%
    split(., .$genome)

  walk(Lgenomes, write_genome)

  OUT_FAA
}

# Main ----

hmmer <- read_tsv(IN)

Lqueries <- hmmer %>%
  split(., .$query)

dir_create(OUT_DIR)

done <- future_map(Lqueries, write_query)
