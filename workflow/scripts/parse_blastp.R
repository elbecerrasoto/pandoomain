#!/usr/bin/Rscript
library(tidyverse)
library(stringr)
library(segmenTools)
library(Rgff)

args <- commandArgs(trailingOnly = TRUE)

BLASTP <- args[1] # "results/genomes/GCF_900110305.1/blastp.tsv"
GFF <- args[2] # "results/genomes/GCF_900110305.1/GCF_900110305.1.gff"
OUT <- args[3] # "x.tsv"


HEADER <- c("QueryID", "SubjectID", "PercentageIdentity", "QueryCoverage", "SubjectCoverage", "EValue")

IDENTITY <- 30
QCOVERAGE <- 60
SCOVERAGE <- 60
EVAL <- 0.05


Rgff::check_gff(GFF)

get_genome <- function(path) {
  str_replace(path, ".*(GC[FA]_[0-9]+\\.[0-9])\\.gff+", "\\1")
}



graceful_exit <- function() {
  write_tsv(tibble(), OUT)
  quit(status = 0)
}

GENOME <- get_genome(GFF)
REFSEQ <- str_detect(GENOME, "GCF")

blastp <- read_tsv(BLASTP, col_names = HEADER, comment = "#", )

blastp <- blastp |>
  filter(
    PercentageIdentity >= IDENTITY,
    QueryCoverage >= QCOVERAGE,
    SubjectCoverage >= SCOVERAGE,
    EValue <= EVAL
  )

if (nrow(blastp) < 2) graceful_exit()

contigs <- segmenTools::gff2tab(GFF) |>
  tibble() |>
  filter(feature == "region") |> # only CDS
  select_if({
    \(x) !(all(is.na(x)) | all(x == ""))
  }) # exclude empty cols


gff <- segmenTools::gff2tab(GFF) |>
  tibble() |>
  filter(feature == "CDS") |> # only CDS
  select_if({
    \(x) !(all(is.na(x)) | all(x == ""))
  }) # exclude empty cols

if ("pseudo" %in% names(gff)) {
  gff <- gff |>
    filter(is.na(pseudo))
}

# definition of neighbor
# doit by contig
gff <- gff |>
  group_by(seqname) |>
  arrange(start) |>
  mutate(order = seq_along(start)) |>
  relocate(order) |>
  ungroup()

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
    contig <- contigs |>
      filter(seqname == contig1)

    contig_gff <- gff |>
      filter(seqname == contig1)

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
      gene1_order = gene1$order,
      gene2_order = gene2$order,
      gene1_first = gene1_first,
      contig = contig1,
      contig_ostart = min(contig_gff$order),
      contig_oend = max(contig_gff$order),
      contig_start = contig$start,
      contig_end = contig$end,
      gene1_start = gene1$start,
      gene1_end = gene1$end,
      gene2_start = gene2$start,
      gene2_end = gene2$end,
      refseq = REFSEQ
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
