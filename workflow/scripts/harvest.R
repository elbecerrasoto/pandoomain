#!/usr/bin/env Rscript

# So harvest a table
# with: a pid & genome colss
# and a implicit DB

# harvest.R --db genomes -i pids.tsv
# genome, pid, query, DB

library(tidyverse)
library(stringr)

IN <- "tests/results/hmmer.tsv"
N_TXT <- 5

hmmer <- read_tsv(IN)

hmmer <- hmmer |>
  mutate(query_out = str_c(query,
                           "_",
                           str_sub(query_txt, 1, N_TXT),
                           ".faa"))


