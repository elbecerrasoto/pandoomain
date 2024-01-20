library(tidyverse)
library(segmenTools)
library(Rgff)

GFF <- "/home/ebecerra/2-projects/viuva/results/genomes/GCA_000743215.1/GCA_000743215.1.gff"
# GFF quality
Rgff::check_gff(GFF)
Rgff::gff_stats(GFF)
x <- Rgff::get_features(GFF)

BLASTP <- "/home/ebecerra/2-projects/viuva/results/genomes/GCA_000743215.1/blastp.tsv"
HEADER <- c("QueryID", "SubjectID", "PercentageIdentity", "QueryCoverage", "SubjectCoverage", "EValue")

IDENTITY <- 30
QCOVERAGE <- 60
SCOVERAGE <- 60
EVAL <- 0.05

blastp <- read_tsv(BLASTP, col_names = HEADER, comment = "#", )

blastp <- blastp |>
  filter(
    PercentageIdentity >= IDENTITY,
    QueryCoverage >= QCOVERAGE,
    SubjectCoverage >= SCOVERAGE,
    EValue <= EVAL
  )

gff <- segmenTools::gff2tab(GFF) |>
  tibble() |>
  filter(feature == "CDS") |> # only CDS
  select_if({
    \(x) !(all(is.na(x)) | all(x == ""))
  }) # exclude empty cols

# some don't have them annotated, GenBank
# gff <- gff |>
# filter(is.na(pseudo)) # exclude pseudogenes
