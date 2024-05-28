#!/usr/bin/env sh

TAXID="1423"
TAXID_refseq="${TAXID}_refseq.tsv"
OUT="genomes.txt"

utils/get_taxid_refseq.R "$TAXID"
cut -f1 -d$'\t' "$TAXID_refseq" | sed '1d' >| "$OUT"

# Execution
# remove -np to execute
# nohup bash -c "/usr/bin/time --verbose snakemake --cores all -np" >| sm.out 2>| sm.err &
