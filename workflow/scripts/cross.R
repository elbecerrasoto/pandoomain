#!/usr/bin/env Rscript
library(tidyverse)

TAXID_ALL <- "tests/results/.taxallnomy_lin_name.txt"
TAXID_HITS <- "tests/results/genomes_metadata.tsv"

TREE <- "tests/results/taxallnomy_lin_name.tsv"

taxid_all <- read_tsv(TAXID_ALL, col_names = F)[[1]]
taxid_hits <- read_tsv(TAXID_HITS)$tax_id

# Test if is faster with unique or sort
rows_on_read <- sort(which(taxid_all %in% taxid_hits))


# subset the taxallnomy tablet
# to only relevant entries

tree <- file(TREE, "r")

i <- 1
row <- 1
while(0 != length(line <- readLines(tree, n = 1))) {
  if (rows_on_read[[row]] == i) {
    # cat(line) slow writes
    
    if (row == length(rows_on_read)) break
    
    row <- row + 1
  }
  
  i <- i + 1
}

close(tree)

# Hold on RAM, do not write
# WIP, do the join

