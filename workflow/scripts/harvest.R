#!/usr/bin/env Rscript

# Works on anything
# Does has the columts
# genome & pid

# Globals ----

suppressPackageStartupMessages({
  library(tidyverse)
  library(furrr)
  library(seqinr)
})

argv <- commandArgs(trailingOnly = TRUE)


DB <- argv[[1]]
CORES <- as.integer(argv[[2]])
IN <- argv[[3]]

## DB <- "tests/results/genomes"
## IN <- "tests/results/hmmer.tsv"
## CORES <- 12

plan(multicore, workers = CORES)


neis <- read_tsv(IN, show_col_types = FALSE)



neis <- neis |>
  distinct(pid, .keep_all = TRUE)

Lgenomes <- neis %>%
  split(., .$genome)


write_genome <- function(genome_tib) {
  genome <- unique(genome_tib$genome)
  in_genome <- paste0(DB, "/", genome, "/", genome, ".faa")
  pids <- unique(genome_tib$pid)

  stopifnot(length(genome) == 1)

  faa <- read.fasta(in_genome, seqtype = "AA", strip.desc = TRUE)
  faa <- faa[names(faa) %in% pids]

  #  cat(".", file = stderr())
  #  flush.console()

  faa
}



done <- future_map(Lgenomes, possibly(write_genome, NULL))

out_len <- sum(map_int(done, length))
out <- vector(mode = "list", length = out_len)

i <- 1
for (genome in done) {
  for (faa in genome) {
    out[[i]] <- faa
    i <- i + 1
  }
}

get_headers <- function(faa) {
  map_chr(faa, \(s) attr(s, "Annot"))
}


suppressWarnings({
  # Suppresing Warning on file() call inside write.fasta
  # Warning:
  # In file(description = file.out, open = open) :
  # using 'raw = TRUE' because '/dev/stdout' is a fifo or pipe
  write.fasta(out, get_headers(out),
    "/dev/stdout",
    open = "a",
    nbchar = 80
  )
})
