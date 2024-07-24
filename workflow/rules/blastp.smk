# include: "globals.smk"


rule makedb:
    input:
        faa=f"{RESULTS_GENOMES}/{{genome}}/{{genome}}.faa",
    output:
        db=f"{RESULTS_GENOMES}/{{genome}}/{{genome}}.dmnd",
    params:
        db=f"{RESULTS_GENOMES}/{{genome}}/{{genome}}",
    shell:
        """
        diamond makedb --db {params.db} --in {input.faa}
        """


rule blastp:
    input:
        query=IN_QUERIES,
        db=rules.makedb.output.db,
    output:
        tsv6=f"{RESULTS_GENOMES}/{{genome}}/{{genome}}_blast.tsv",
    params:
        format=f"6 {BLAST_FORMAT}",  # Number 6 is for ncbi blast tabular format
        db=rules.makedb.params.db,
        extra_args=f"{DIAMOND_ARGS}",
    shell:
        """
        diamond blastp --outfmt {params.format}\
            --out   {output.tsv6}\
            --db    {params.db}\
            --query {input.query}\
            {params.extra_args}
        perl -i -ne 'print "{wildcards.genome}\\t" . "$_"' {output.tsv6}
        """


rule bind_blasts:
    input:
        ALL_BLASTS,
    output:
        f"{RESULTS}/{BLASTS_TSV}",
    params:
        header=BLAST_HEADER,
    shell:
        """
        cat - {input} >| {output} <<< '{params.header}'
        """


rule all_proteins:
    input:
        rules.bind_blasts.output,
    output:
        f"{RESULTS}/{BLASTS_FAA}",
    params:
        width="80",
    log:
        f"{LOGS}/all_proteins.log",
    shell:
        """
        workflow/scripts/blast2faa.R {input} | fasta_pretty -w={params.width} >| {output}
        fasta_unique {output} > /dev/null 2> {log}
        if [[ ! -s {log} ]]
        then
            printf "Warning:\\nSome protein IDs map to the same sequence.\\n"
            printf "You do not need to do anything, it just the way NCBI sequences are.\\n"
            cat {log}
        fi
        """
