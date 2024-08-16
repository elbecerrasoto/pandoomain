#!/usr/bin/env sh

IN="$1"
DRY="$2"
OUT="genomes"

# Max number before URL error: 504!
LINES="480"
API_KEY="--api-key 80e90a387605463df09ac9121d0caa0b7108"
INCLUDE="--include protein,gff3"

MKDIR=' mkdir -p '"$OUT"'/{#} '
DATASETS=' datasets download genome accession {} --dehydrated --filename '"$OUT"'/{#}/{#}.zip '" $INCLUDE "" $API_KEY "
UNZIP=' unzip '"$OUT"'/{#}/{#}.zip -d '"$OUT"'/{#} '
REHYDRATE=' datasets rehydrate --directory '"$OUT"'/{#} '" $API_KEY "

PARALLEL_CMD="$MKDIR && $DATASETS && $UNZIP && $REHYDRATE"


if [[ ! -e "$IN" ]]
then
    printf "Please provide input genome list as 1st arg."
    exit 0
fi

if [[ "$DRY" == "GO" ]]
then
    parallel -l "$LINES" "$PARALLEL_CMD" :::: "$IN"
else
    printf "Supply 2nd argument with the word GO to start.\n"
    parallel -l "$LINES" --dry-run "$PARALLEL_CMD" :::: "$IN"
fi
