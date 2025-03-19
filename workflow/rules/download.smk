# include: "globals.smk"


rule get_metadata_raw:
    input:
        in_genomes=IN_GENOMES,
    output:
        metadata_raw=f"{RESULTS}/.genomes_metadata_raw.tsv",
    cache: True
    shell:
        """
        perl -MList::Util=uniq -ne\
            'push @genomes, $1 if /(GC[AF]_\\d+\\.\\d)/; END {{ print join("\\n", uniq(@genomes)), "\\n"; }}' \
        {input} | \
        \
        datasets summary genome accession \
            --inputfile /dev/stdin \
            --as-json-lines | \
        tr -d '\\t' | \
        dataformat tsv genome | \
        tr -d '\\r' >| {output}
        """


rule get_metadata:
    input:
        metadata_raw=rules.get_metadata_raw.output,
    output:
        metadata=f"{RESULTS}/genomes_metadata.tsv",
    shell:
        """
workflow/scripts/genome_metadata.R {input} >| {output}
"""


def get_genomes_dir(wc, output):
    return str(Path(output[0]).parent)


rule download_genomes:
    input:
        in_genomes=IN_GENOMES,
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
        tar_gz=f"{RESULTS}/taxallnomy.tar.gz",
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
        tar_gz=rules.taxallnomy_targz.output,
    output:
        taxallnomy=f"{RESULTS}/taxallnomy_lin_name.tsv",
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
        ranks=f"{RESULTS}/genomes_ranks.tsv",
    cache: True
    shell:
        """
workflow/scripts/cross.R {input} >| {output}
"""
