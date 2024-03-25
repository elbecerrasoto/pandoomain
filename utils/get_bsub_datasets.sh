#!/usr/bin/bash

RAW="bsub_datasets_raw.tsv"
OUT="bsub_datasets.tsv"
TAXID="1423"

datasets summary genome taxon "$TAXID"\
                                    --as-json-lines\
                                    --annotated\
                                    --exclude-atypical |\
  dataformat tsv genome >|\
  "$RAW"

perl -pe 's/\r//g' "$RAW" |\
perl -pe 's/Biological Resource Center, \t/Biological Resource Center, /g' >|\
  "$OUT"