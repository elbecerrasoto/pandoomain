#!/usr/bin/Rscript
library(tidyverse)
library(stringr)
library(segmenTools)
library(Rgff)

args <- commandArgs(trailingOnly = TRUE)

print(args)

OUT <- args[3]

BLASTP <- args[1]
HEADER <- c("QueryID", "SubjectID", "PercentageIdentity", "QueryCoverage", "SubjectCoverage", "EValue")

IDENTITY <- 30
QCOVERAGE <- 60
SCOVERAGE <- 60
EVAL <- 0.05

GFF <- args[2]
Rgff::check_gff(GFF)

get_genome <- function(path) {
  str_replace(path, ".*(GC[FA]_[0-9]+\\.[0-9])\\.gff+", "\\1")
}

graceful_exit <- function() {
  write_tsv(tibble(), OUT)
  quit(status = 0)
}

GENOME <- get_genome(GFF)

blastp <- read_tsv(BLASTP, col_names = HEADER, comment = "#", )

blastp <- blastp |>
  filter(
    PercentageIdentity >= IDENTITY,
    QueryCoverage >= QCOVERAGE,
    SubjectCoverage >= SCOVERAGE,
    EValue <= EVAL
  )

if (nrow(blastp) < 2) graceful_exit()


gff <- segmenTools::gff2tab(GFF) |>
  tibble() |>
  filter(feature == "CDS") |> # only CDS
  select_if({
    \(x) !(all(is.na(x)) | all(x == ""))
  }) # exclude empty cols

# definition of neighbor
gff <- gff |>
  arrange(start) |>
  mutate(order = 1:nrow(gff))

queries <- group_split(blastp, QueryID)

if (length(queries) < 2) graceful_exit()

genes_q1 <- gff |>
  filter(protein_id %in% queries[[1]]$SubjectID)
genes_q2 <- gff |>
  filter(protein_id %in% queries[[2]]$SubjectID)

calc <- function(gene1, gene2) {
  contig1 <- gene1$seqname
  contig2 <- gene2$seqname

  if (identical(contig1, contig2)) {
    s2 <- max(gene1$start, gene2$start)
    e1 <- min(gene1$end, gene2$end)
    distance <- s2 - e1
    gene_count <- abs(gene1$order - gene2$order)
    same_strand <- identical(gene1$strand, gene2$strand)
    gene1_first <- gene1$order < gene2$order
    return(list(
      genome = GENOME,
      gene1 = gene1$protein_id,
      gene2 = gene2$protein_id,
      distance = distance,
      gene_count = gene_count,
      same_strand = same_strand,
      gene1_first = gene1_first,
      contig = contig1
    ))
  } else {
    return(list())
  }
}

lresults <- vector("list", length = nrow(genes_q1) * nrow(genes_q2))
n <- 0

for (i in seq_len(nrow(genes_q1))) {
  for (j in seq_len(nrow(genes_q2))) {
    n <- n + 1
    gene1 <- genes_q1[i, ]
    gene2 <- genes_q2[j, ]
    lresults[[n]] <- calc(gene1, gene2)
  }
}

results <- bind_rows(map(lresults, as_tibble))
write_tsv(results, OUT, col_names = FALSE)
