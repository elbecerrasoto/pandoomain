library(tidyverse)
library(segmenTools)
library(Rgff)

GFF <- "/home/ebecerra/2-projects/viuva/results/genomes/GCA_000743215.1/GCA_000743215.1.gff"
# GFF quality
Rgff::check_gff(GFF)
# Rgff::gff_stats(GFF)
# Rgff::get_features(GFF)

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

# definition of neighbor
gff <- gff |>
  arrange(start) |>
  mutate(order = 1:nrow(gff))


# some don't have them annotated, GenBank
# with Rgff, check if they have pseudogenes?
# gff <- gff |>
# filter(is.na(pseudo)) # exclude pseudogenes

blastp <- bind_rows(blastp, blastp)
queries <- group_split(blastp, QueryID)

gene1 <- gff |>
  filter(protein_id %in% queries[[1]]$SubjectID)
gene2 <- gff |>
  filter(protein_id %in% queries[[2]]$SubjectID)
