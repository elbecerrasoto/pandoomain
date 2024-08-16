#!/usr/bin/env sh

IN="$1"
DRY="$2"
OUT="genomes"
OUT_ZIP="$OUT/genomes.zip"

API_KEY="80e90a387605463df09ac9121d0caa0b7108"
INCLUDE="protein,gff3"


MKDIR="mkdir -p $OUT"
DEHYDRATE="datasets download genome accession --inputfile $IN --dehydrated --filename $OUT_ZIP --include $INCLUDE --api-key $API_KEY"
UNZIP="unzip $OUT_ZIP -d $OUT"
HYDRATE="datasets rehydrate --directory $OUT_ZIP --api-key $API_KEY"


if [[ ! -e "$IN" ]]
then
    printf "Please provide input genome list as 1st arg."
    exit 0
fi

if [[ "$DRY" == "GO" ]]
then
    $MKDIR
    $DEHYDRATE
    $UNZIP
    $HYDRATE
else
    printf "Dry Run: Printing Commands.\n"
    printf "Supply 2nd argument with the word GO to start.\n\n"

    printf "$MKDIR\n\n"
    printf "$DEHYDRATE\n\n"
    printf "$UNZIP\n\n"
    printf "$HYDRATE\n\n"
fi

