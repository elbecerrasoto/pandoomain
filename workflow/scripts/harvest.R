#!/usr/bin/env Rscript

# Works on anything
# that has the columns
# genome & pid

# Globals ----

suppressPackageStartupMessages({
  library(tidyverse)
  library(furrr)
  library(seqinr)
})

argv <- commandArgs(trailingOnly = TRUE)


FAA_WIDTH <- as.integer(argv[[1]])
DB <- argv[[2]]
CORES <- as.integer(argv[[3]])
IN <- argv[[4]]


plan(multicore, workers = CORES)


neis <- read_tsv(IN, show_col_types = FALSE)



neis <- neis |>
  distinct(pid, .keep_all = TRUE)

Lgenomes <- neis %>%
  split(., .$genome)


read_genome <- function(genome_tib) {
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



done <- future_map(Lgenomes, possibly(read_genome, NULL))

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

names(out) <- get_headers(out)
out <- out[sort(names(out))]

suppressWarnings({
  # Suppresing Warning on file() call inside write.fasta
  # Warning:
  # In file(description = file.out, open = open) :
  # using 'raw = TRUE' because '/dev/stdout' is a fifo or pipe
  write.fasta(out, names(out),
    "/dev/stdout",
    open = "a",
    nbchar = FAA_WIDTH
  )
})
