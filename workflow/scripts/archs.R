#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
})

set.seed(827540)

argv <- commandArgs(trailingOnly = TRUE)

ISCAN <- argv[[1]]
# ISCAN <- "tests/results/iscan.tsv"

OUT_DIR <- argv[[2]]
# OUT_DIR <- "tests/results/"

OUT <- paste0(OUT_DIR, "/", "archs.tsv")
OUT_PIDFOCUS <- paste0(OUT_DIR, "/", "archsPIDF.tsv")
OUT_CODE <- paste0(OUT_DIR, "/", "archsCODE.tsv")


one_lettercode <- function(doms) {
  doms <- unique(doms)

  OG <- c(46, 60:70, 97:122)
  START <- 192
  OFF <- 64 # para hacerlos todavia mas distintos

  if (length(OG) >= length(doms)) {
    SAMPLE <- sample(OG, length(doms), replace = F)
  } else {
    extra <- START:(START + (length(doms) - length(OG)) + OFF)
    SAMPLE <- sample(c(OG, extra), length(doms), replace = F)
  }

  START_U <- 192 + length(doms)

  STEP <- #
    OUT <- vector(mode = "list", length = length(doms))
  names(OUT) <- doms

  i <- 1
  for (dom in doms) {
    Ucode <- intToUtf8(SAMPLE[[i]])
    OUT[[dom]] <- Ucode
    i <- i + 1
  }
  OUT
}

replace_to_oneletter <- function(archs, code) {
  keys <- names(code)
  for (key in keys) {
    archs <- str_replace_all(archs, key, code[[key]])
  }
  str_replace_all(archs, ",", "")
}


get_arch_len <- function(arch) {
  str_split(arch, ",") |>
    map_int(length)
}

# Main ----

iscan <- read_tsv(ISCAN)

archs <- iscan |>
  filter(analysis == "Pfam", recommended) |>
  group_by(pid) |>
  reframe(
    domain = memberDB, start = start, end = end,
    length = length, domain_txt = memberDB_txt
  ) |>
  arrange(pid, start, end) |>
  mutate(
    start = as.integer(start),
    end = as.integer(end),
    length = as.integer(length)
  )

archs <- archs |>
  group_by(pid) |>
  reframe(order = 1:length(start), across(everything())) |>
  relocate(order, .after = domain)


pid_focus <- archs |>
  group_by(pid) |>
  summarize(
    pid = unique(pid),
    arch = str_flatten(domain, collapse = ",")
  )

ONE_LETTER <- one_lettercode(archs$domain)

pid_focus <- pid_focus |>
  left_join(
    distinct(archs, pid, length),
    join_by(pid)
  ) |>
  mutate(ndoms = get_arch_len(arch)) |>
  relocate(ndoms, .after = arch)


pid_focus <- pid_focus |>
  mutate(arch_code = replace_to_oneletter(arch, ONE_LETTER))

one_letter_chr <- ONE_LETTER |>
  unlist()

one_letter_tib <- tibble(
  domain = names(one_letter_chr),
  letter = one_letter_chr
)


write_tsv(archs, OUT)
write_tsv(pid_focus, OUT_PIDFOCUS)
write_tsv(one_letter_tib, OUT_CODE)
