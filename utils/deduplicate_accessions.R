#!/usr/bin/Rscript

library(glue)
library(tidyverse)
library(segmenTools)

args <- commandArgs(trailingOnly = TRUE)


# Globals ----


# Input
GFF <- "results/genomes/GCF_000699465.1/GCF_000699465.1.gff"
MAPPINGS <- "mappings_filtered.tsv"


get_genome <- function(path) {
  str_extract(path, "GC[FA]_[0-9]+\\.[0-9]")
}
GENOME <- get_genome(GFF)


# Output
BASE <- "hits"
OUT <- glue("{GENOME}_{BASE}.tsv")

OUT_COLS <- c(
  "genome",
  "pid",
  "gene",
  "q_alias",
  "order",
  "start",
  "end",
  "contig",
  "strand",
  "locus_tag",
  "query",
  "domains",
  "product"
)


# Helpers ----


read_cds <- function(gff_path) {
  gff <- segmenTools::gff2tab(gff_path) |>
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

  # definition of neighbor
  # same contig, order by start position
  gff <- gff |>
    group_by(seqname) |>
    arrange(start) |>
    mutate(order = seq_along(start)) |>
    relocate(order)

  gff
}


# Policy ----

normal <- read_cds(GFF)


ISSUES <- c(
  "results/genomes/GCA_009866865.1/GCA_009866865.1.gff",
  "results/genomes/GCA_003990435.1/GCA_003990435.1.gff",
  "results/genomes/GCA_002201955.1/GCA_002201955.1.gff",
  "results/genomes/GCA_007829495.1/GCA_007829495.1.gff"
)

issues_names <- ISSUES |>
  map_chr(get_genome)

issues <- ISSUES |>
  map(read_cds) |>
  `names<-`(issues_names)

issues |>
  map(names)


view(issues[[1]])
names(normal)


NO_IS <- c(
  "results/genomes/GCA_905315025.2/GCA_905315025.2.gff",
  "results/genomes/GCA_905315035.2/GCA_905315035.2.gff",
  "results/genomes/GCA_905315045.2/GCA_905315045.2.gff",
  "results/genomes/GCA_905315055.2/GCA_905315055.2.gff",
  "results/genomes/GCA_905315375.1/GCA_905315375.1.gff",
  "results/genomes/GCA_905315385.1/GCA_905315385.1.gff"
)


no_issues <- NO_IS |>
  map(read_cds)

no_issues |>
  map(names)


genomes <- read_tsv("~/2-projects/hoox/genomes.txt", col_names = "accession")


Test <- genomes$accession[1000:1010]
str_detect(Test, "^GCA_")

is_refseq <- function(accession) {

}

typeof(1)
typeof(as.integer(1))

as.integer(str_extract(Test, "\\d+"))
as.integer(str_extract(Test, "\\d$"))

str_c("hello", "world")

genomes <- genomes |>
  mutate(
    ref_seq = str_detect(accession, "^GCF_"),
    id = str_extract(accession, "\\d+"),
    version = str_extract(accession, "\\d$"),
    id.version = str_extract(accession, "\\d+\\.\\d$")
  )

genomes

genomes |>
  group_by(id) |>
  summarize(length())

# Repetitions are 2 or 1
genomes |>
  count(id) |>
  filter(!(n %in% c(1, 2)))


f <- function(a) {
  genomes |>
    count(id.version) |>
    filter(n == {{ a }}) |>
    nrow()
}


n <- genomes |> nrow()

one_two <- c(1, 2) |>
  map_int(f)

stopifnot(
  one_two %>%
    `*`(1:2) |>
    sum() == n
)

# Contarlos es encontrarlos?

genomes_with1 <- genomes |>
  count(id.version) |>
  filter(n == 1) |>
  semi_join(genomes, y = _)

# There are 43 that are unique
genomes_with1 |>
  count(ref_seq)

# applying conditonaly a trasformation


x_GCA <- genomes |>
  group_by(id.version) |>
  summarise(best_gff = max(ref_seq)) |>
  filter(best_gff == 0) |>
  mutate(accession = str_c("GCA_", id.version))

x <- bind_rows(x_GCF, x_GCA)

NO_repetitions <- semi_join(genomes, x, join_by(accession == accession))

NO_repetitions |>
  select(accession) |>
  write_tsv("genomes_norepetitions.txt", col_names = F)


NO_repetitions |>
  count(id.version) |>
  filter(n != 1)
