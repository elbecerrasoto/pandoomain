# include: "globals.smk"


rule get_metadata_raw:
    input:
        ancient(USED_GENOMES),
    output:
        f"{RESULTS}/genomes_metadata_raw.tsv",
    priority: 1
    retries: 3
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


def params_output_name(wc, output):
    """
    Used by taxallnomy_targz
    """
    return Path(output[0]).name


rule taxallnomy_targz:
    output:
        f"{RESULTS}/taxallnomy.tar.gz",
    priority: 1
    retries: 3
    cache: True
    params:
        url="https://sourceforge.net/projects/taxallnomy/files/latest/download",
        output_name=params_output_name,
    shell:
        """
        aria2c --dir {RESULTS}\
            --continue=true --split 12\
            --max-connection-per-server=16\
            --min-split-size=1M\
            --out={params.output_name}\
            --quiet\
            {params.url}
        """


rule taxallnomy_linname:
    input:
        rules.taxallnomy_targz.output,
    output:
        f"{RESULTS}/taxallnomy_lin_name.tsv",
    cache: True
    params:
        ori=f"{RESULTS}/taxallnomy_database/taxallnomy_lin_name.tab",
    shell:
        """
        tar --directory={RESULTS} -vxf {input}
        mv {params.ori} {output}
        """


rule join_genomes_taxallnomy:
    input:
        taxallnomy=rules.taxallnomy_linname.output,
        genomes=rules.get_metadata.output,
    output:
        f"{RESULTS}/genomes_ranks.tsv",
    cache: True
    shell:
        """
        workflow/scripts/cross.R {input} >| {output}
        """
