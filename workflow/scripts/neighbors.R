#!/usr/bin/Rscript


suppressPackageStartupMessages({
  library(tidyverse)
  library(rlang) # warnings utils
  library(segmenTools)
  library(glue)
})


# Globals ----

ARGV <- commandArgs(trailingOnly = TRUE)

HMMER <- "tests/results/hmmer.tsv"
# HMMER <- ARGV[[1]]

N <- 8
# N <- ARGV[[2]]

GFF <- "tests/results/genomes/GCF_001286845.1/GCF_001286845.1.gff"
# GFF <- ARGV[[3]]


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

GENOME_RE <- "GC[FA]_[0-9]+\\.[0-9]"


# Helpers ----


read_gff <- function(path) {
  igenome <- str_extract(path, GENOME_RE)

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

  msg <- glue("The following columns were not present:\n{str_flatten(absent, collapse = ' ')}\nOn the file:\n{GFF}")

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


# Code ----

# how to declare hmmer as RAM object?
# declare hmmer as a resource
# and model it as a FIFO (pipe).
igenome <- str_extract(GFF, GENOME_RE)

gff <- read_gff(GFF)
gff <- gff |>
  mutate(row = 1:nrow(gff)) |>
  relocate(row)

hmmer <- read_tsv(HMMER, show_col_types = FALSE)

hmmer <- hmmer |>
  filter(genome == igenome) |>
  distinct(genome, pid, query) |>
  group_by(pid) |>
  summarize(queries = list(query))

queries <- hmmer$queries
names(queries) <- hmmer$pid

queries
class(queries[["WP_072173970.1"]])

pids <- unique(hmmer$pid)

hits <- gff |>
  filter(pid %in% pids)

rows <- hits$row
pids <- hits$pid

starts <- if_else(rows + N <= nrow(gff), rows + N, nrow(gff))
ends <- if_else(rows - N >= 1, rows - N, 1)

OUT <- vector(length = length(rows), mode = "list")
for (i in seq_along(rows)) {
  matched_queries <- queries[pids[i]]

  s <- starts[i]
  e <- ends[i]
  CONTIG <- gff[rows[i], ]$contig

  subgff <- gff[s:e, ] |>
    filter(contig == CONTIG)

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

  OUT[[i]] <- outi
}


x <- bind_rows(OUT)

SELECT <- c("genome", "nei", "neioff", "order", "pid", "gene", "product", "start", "end", "strand", "frame", "locus_tag", "contig", "queries")

x <- x |>
  select(all_of(SELECT))

y <- x |>
  group_by(pid) |>
  reframe(query = unlist(queries)) |>
  mutate(presence = TRUE) |>
  pivot_wider(
    names_from = query,
    values_from = presence,
    values_fill = FALSE,
    names_sort = TRUE
  )

z <- left_join(y, x, join_by(pid)) |>
  relocate(all_of(SELECT)) |>
  arrange(genome, nei, neioff)
