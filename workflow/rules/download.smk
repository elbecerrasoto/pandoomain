# include: "globals.smk"


rule download_genome:
    output:
        multiext(f"{RESULTS_GENOMES}/{{genome}}/{{genome}}", ".gff", ".faa"),
    params:
        include="protein gff3",
    retries: 3
    cache: "omit-software"
    shell:
        """
        workflow/scripts/download_genome.py --include {params.include} --out-dir {RESULTS_GENOMES}/{wildcards.genome} -- {wildcards.genome}
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
