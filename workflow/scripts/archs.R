#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
})


argv <- commandArgs(trailingOnly = TRUE)

ISCAN <- argv[[1]]
# ISCAN <- "tests/results/iscan.tsv"

OUT <- argv[[2]]
OUT_PIDFOCUS <- argv[[3]]
OUT_CODE <- argv[[4]]

OFFSET <- 33
PF_INT_LEN <- 5
PF_LEAD_CHAR <- "PF"

one_lettercode <- function(doms) {
  # Avoids invisible characters

  doms <- unique(doms)

  pfam_chars <- str_extract(doms, "\\d+")
  stopifnot("Bad PFAM ID." = all(str_length(pfam_chars) == PF_INT_LEN))

  pfam_ints <- as.integer(pfam_chars)

  OUT <- as.list(str_split_1(intToUtf8(pfam_ints + OFFSET), ""))
  names(OUT) <- doms

  OUT
}


code_to_pfam <- function(codes) {
  TOTAL_LEN <- PF_INT_LEN + str_length(PF_LEAD_CHAR)

  pfam_ints <- utf8ToInt(codes) - OFFSET
  pfam_chars <- as.character(pfam_ints)

  appends <- map_chr(
    PF_INT_LEN - str_length(pfam_chars),
    \(x) ifelse(x > 0, str_flatten(rep("0", x)), "")
  )

  OUT <- str_c(PF_LEAD_CHAR, appends, pfam_chars)
  stopifnot("Bad PFAM ID" = all(str_length(OUT) == TOTAL_LEN))

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

iscan <- read_tsv(ISCAN, show_col_types = FALSE)

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
