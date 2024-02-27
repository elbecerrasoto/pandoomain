OUT <- "blasts.faa"
FAA_FORMAT <- 80 # NCBI


IN <- "blast_YwqJdomain.tsv"

library(seqinr)
library(tidyverse)

x <- read_tsv(IN)

write.fasta(as.list(x$full_sseq),
  file.out = OUT,
  names = x$stitle, nbchar = FAA_FORMAT
)
