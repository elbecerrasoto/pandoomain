library(tidyverse)

BLASTP <- "/home/ebecerra/2-projects/viuva/results/genomes/GCA_000743215.1/blastp.tsv"
HEADER <- c("QueryID", "SubjectID", "PercentageIdentity", "QueryCoverage", "SubjectCoverage", "EValue")

IDENTITY <- 30
QCOVERAGE <- 60
SCOVERAGE <- 60
EVAL <- 0.05

blastp <- read_tsv(BLASTP, col_names = HEADER, comment = "#",)

blastp |> 
  filter(PercentageIdentity >= IDENTITY, 
         QueryCoverage >= QCOVERAGE,
         SubjectCoverage >= SCOVERAGE,
         EValue <= EVAL)
