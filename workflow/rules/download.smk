# include: "globals.smk"


rule get_metadata_raw:
    input:
        ancient(USED_GENOMES),
    output:
        f"{RESULTS}/genomes_metadata_raw.tsv",
    priority: 1
    cache: True
    params:
        no_header=f"{RESULTS}/.genomes.txt",
    shell:
        """
        sed '1d' {input} | perl -ape '$_ = $F[1] . "\\n"' >| {params}

        datasets summary genome accession \
            --inputfile {params} \
            --as-json-lines |\
        tr -d '\\t' |\
        dataformat tsv genome |\
        tr -d '\\r' >| {output}
        """


rule get_metadata:
    input:
        rules.get_metadata_raw.output,
    output:
        f"{RESULTS}/genomes_metadata.tsv",
    shell:
        """
        workflow/scripts/genome_metadata.R {input} >| {output}
        """


rule download_genome:
    output:
        multiext(f"{RESULTS_GENOMES}/{{genome}}/{{genome}}", ".gff", ".faa"),
    params:
        include="protein gff3",
        genome="{genome}",
    retries: 3
    cache: True
    shell:
        """
        workflow/scripts/download_genome.py --include {params.include} --out-dir {RESULTS_GENOMES}/{params.genome} -- {params.genome}
        """


rule cds:
    input:
        gff=rules.download_genome.output[0],
    output:
        cds=f"{RESULTS_GENOMES}/{{genome}}/{{genome}}_cds.tsv",
    shell:
        """
        workflow/scripts/reduce_gff2cds.R {input} >| {output}
        """
