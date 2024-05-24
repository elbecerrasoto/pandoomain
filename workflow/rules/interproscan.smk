include: "globals.smk"
include: "blastp.smk"


rule interproscan_xml:
    input:
        faa=rules.all_proteins.output,
    output:
        xml=f"{RESULTS}/{ISCAN_XML}",
    params:
        temp="/tmp",
    threads: workflow.cores
    cache: "omit-software"
    shell:
        """
        interproscan.sh --formats XML\
                        --input {input.faa} \
                        --outfile {output.xml} \
                        --cpu {threads} \
                        --tempdir {params.temp} \
                        --goterms
        """


rule interproscan_tsv:
    input:
        xml=rules.interproscan_xml.output.xml,
    output:
        tsv=f"{RESULTS}/{ISCAN_TSV}",
    params:
        header=ISCAN_HEADER,
        temp="/tmp",
    cache: "omit-software"
    shell:
        """
        interproscan.sh --mode convert \
                        --formats TSV \
                        --input {input.xml} \
                        --outfile {output.tsv}.temp \
                        --goterms \
                        --enable-tsv-residue-annot

        # Annotate headers
        cat - {output.tsv}.temp >| {output.tsv} <<< '{params.header}'

        rm {output.tsv}.temp
        """
