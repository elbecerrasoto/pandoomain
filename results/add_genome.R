#!/usr/bin/Rscript
library(tidyverse)
library(stringr)
library(segmenTools)

ARGS <- commandArgs(trailingOnly = T)

IN_BLAST <- ARGS[1]
IN_GFF <- ARGS[2]

parse_genome <- function(path) {
  str_replace(path, ".*(GC[FA]_[0-9]+\\.[0-9])_blastp.tsv$", "\\1")
}

GENOME <- parse_genome(IN_BLAST)
NAMES <- c("query", "subject", "identity", "qcoverage", "scoverage", "eval")

blast <- IN_BLAST |>
  read_tsv(col_names = NAMES, comment = "#") |> 
  mutate(genome = GENOME) |>
  relocate(genome)

gff <- segmenTools::gff2tab(IN_GFF) |>
  tibble() |>
  filter(feature == "CDS") |> # only CDS
  select_if({
    \(x) !(all(is.na(x)) | all(x == ""))
  }) # exclude empty cols

if ("pseudo" %in% names(gff)) {
  gff <- gff |>
    filter(is.na(pseudo))
}


left_join(blast, gff, by = c("subject" = "protein_id")) |> 
  relocate(gene, locus_tag, .after = subject) |> relocate(product, seqname, start, end, strand, frame, .after = eval) |> 
  select(genome:frame) |> write_tsv(paste0(GENOME, "_blast_expanded.tsv"), col_names = F)
