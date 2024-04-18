#!/usr/bin/bash


readonly OUT_DIR='test/data'
readonly GENOMES_DIR='tests/results/genomes'
readonly CONFIG='test/config.yaml'
readonly N_GFF_NEIGHBORS=24

declare -a\
    GENOMES=( 'GCF_001286845.1' 'GCF_001286885.1' )

declare -a\
    PIDs=( 'WP_072173795\\.1' 'WP_072173796\\.1' )


usr/bin/bash $IFS='|' && printf "%s\n" "${PIDs[$@]}"

# for genome in ((i=0; n < ${GENOMES[#]}; ++i ))
# do
#     FAA[i] =
#     GFFs[i] =
# done


# FAAs="$(fd -I $RE_GENOME.faa$ $GENOMES_DIR)"
# GFFs="$(fd -I $RE_GENOME.gff$ $GENOMES_DIR)"

# REDUCE_FAA="fasta_extract $PIDs    < {1} > $OUT_DIR/{/}"
# REDUCE_GFF="grep -C $N_GFF_NEIGHBORS < {1} > $OUT_DIR/{/}"

# mkdir -p "$OUT_DIR"
# snakemake -c all --configfile "$CONFIG" -- "$FAAs" "$GFFs"

# parallel --dry-run "$REDUCE_FAA" ::: "$FAAs"
# parallel --dry-run "$REDUCE_GFF" ::: "$GFFs"
