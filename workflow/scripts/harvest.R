#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(stringr)
  library(seqinr)
  library(fs)
})

argv <- commandArgs(trailingOnly = TRUE)

DB <- argv[[1]]
IN <- argv[[2]]
OUT_DIR <- argv[[3]]
N_TXT <- 7

# IN <- "tests/results/hmmer.tsv"
# OUT_DIR <- "tests/results/queries"
# DB <- "tests/results/genomes"


get_headers <- function(faa) {
  map_chr(faa, \(s) attr(s, "Annot"))
}

write_queries <- function(pids_tib, genome) {
  PIDS_TIB <- pids_tib
  FAA_ALL <- read.fasta(genome, seqtype = "AA", strip.desc = TRUE)
  dir_create(OUT_DIR)

  queries2write <- PIDS_TIB |>
    pull(query_out) |>
    unique()

  queries2write_full <- str_c(OUT_DIR, "/", queries2write)

  walk(queries2write_full, unlink)

  write_query <- function(query2write) {
    out_file <- str_c(OUT_DIR, "/", query2write)
    qpids <- PIDS_TIB |>
      filter(query_out == query2write) |>
      pull(pid) |>
      unique()
    faa <- FAA_ALL[names(FAA_ALL) %in% qpids]

    write.fasta(faa, get_headers(faa),
      out_file,
      open = "a",
      nbchar = 80
    )
  }

  walk(queries2write, write_query)
}


# Main ----

hmmer <- read_tsv(IN)

hmmer <- hmmer |>
  mutate(
    genome_in = str_c(
      DB, "/", genome, "/", genome,
      ".faa"
    ),
    query_out = str_c(
      query,
      "_",
      str_sub(query_txt, 1, N_TXT),
      ".faa"
    )
  )

genomes <- hmmer |>
  distinct(pid, query_out, .keep_all = TRUE) |>
  select(genome_in, query_out, pid) |>
  arrange(genome_in) %>%
  split(., .$genome_in)

done <- iwalk(genomes, write_queries)
