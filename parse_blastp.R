library(tidyverse)

BLASTP <- "blastp.tsv"
HEADER <- c("QueryID", "SubjectID", "PercentageIdentity", "QueryCoverage", "SubjectCoverage", "EValue")

blastp <- read_tsv(BLASTP, col_names = HEADER, comment = "#",)

blastp |> 
  filter(PercentageIdentity >= 30, 
         QueryCoverage >= 60,
         SubjectCoverage >= 60,
         EValue <= 0.05)
