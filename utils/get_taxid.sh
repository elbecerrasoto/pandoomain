#!/usr/bin/bash

TAXID="$1"
OUT="$1.tsv"

datasets summary genome taxon "$TAXID"\
                                    --as-json-lines\
                                    --annotated\
                                    --exclude-atypical |\
    tr -d '\t' |\
    dataformat tsv genome |\
    tr -d '\r' >| "$OUT"
    # it only works doing the tr to delete \r after dataformat
