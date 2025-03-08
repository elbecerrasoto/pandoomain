# include: "globals.smk"


rule get_genomes_raw:
    input:
        IN_GENOMES,
    output:
        f"{RESULTS}/.genomes_raw.tsv",
    run:
        # weird, input/output substitution only works inside f-string
        utils.sort_filter_genomes(f"{input}", f"{output}", ONLY_REFSEQ)


rule get_metadata_raw:
    input:
        rules.get_genomes_raw.output,
    output:
        f"{RESULTS}/.genomes_metadata_raw.tsv",
    priority: 1
    retries: 3
    cache: True
    shell:
        """
        sed '1d' {input} | perl -ape '$_ = $F[1] . "\\n"' |\
        \
        datasets summary genome accession \
            --inputfile /dev/stdin \
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


def get_genomes_dir(wc, output):
    return str(Path(output[0]).parent)


rule download_genomes:
    input:
        rules.get_genomes_raw.output,
    output:
        genomes=f"{RESULTS}/genomes/genomes.tsv",
        not_found=f"{RESULTS}/genomes/not_found.tsv",
    threads: workflow.cores
    params:
        genomes_dir=get_genomes_dir,
    shell:
        """
workflow/scripts/hydrate.py {threads} {params} {input}
"""


def params_output_name(wc, output):
    """
    Used by taxallnomy_targz
    """
    return str(Path(output[0]).name)


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
