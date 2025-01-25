#!/usr/bin/env python

import datetime
import os
import shlex
import subprocess as sp
import sys
import xml.etree.ElementTree as ET
from multiprocessing import Process
from pathlib import Path
from xml.etree.ElementTree import ElementTree

from Bio import SeqIO

INPUT_FAA = Path(sys.argv[1])
OUT_TSV = Path(sys.argv[2])
OUT_XML = f"{OUT_TSV.stem}.xml"

LOG = Path("iscan.log")
VERBOSE = True
CLEAN_TMP = False

ENCODING = "utf-8"

TMP_FAA = Path("tmp.faa")
TMP_XML = Path("tmp.xml")

BATCH_SIZE = 3
CPUS = 12
XML_CMD_PARS = Path("/tmp")


def run_log(cmd, input_stream, log=None, verbose=False):

    def write(msg, handler):
        handler.write(msg)

    if log:
        hlog = open(log, "a", encoding=ENCODING)

    start = datetime.datetime.today()

    msg = f"Starting at {start}\n" + f"Running:\n{shlex.join(cmd)}\n"
    if verbose:
        write(msg, sys.stderr)
    if log:
        write(msg, hlog)

    with open(input_stream, "r", encoding=ENCODING) as input_handler:
        completed = sp.run(
            cmd,
            input=input_handler.read(),
            check=True,
            capture_output=True,
            encoding=ENCODING,
        )

    finish = datetime.datetime.today()

    msg = (
        f"Finished at {finish}\n"
        + f"Time taken was {finish-start}\n"
        + f"STDOUT:\n"
        + f"{completed.stdout}\n"
        + f"STDERR:\n"
        + f"{completed.stderr}\n"
    )
    if verbose:
        write(msg, sys.stderr)

    if log:
        write(msg, hlog)
        hlog.close()


def merge_ETs(*trees: tuple[ElementTree, ...]) -> ElementTree:

    main_tree = trees[0]
    base_root = main_tree.getroot()

    for tree in trees[1:]:
        base_root.extend(tree.getroot())

    return main_tree


def create_fifo(path):
    path = Path(path)
    if not path.exists():
        os.mkfifo(path)
    if not path.is_fifo():
        raise FileExistsError(f"{path} already exists and it is not a FIFO.")
    return path


def xml_cmd_gen(output, cpus=CPUS, params=XML_CMD_PARS):
    return [
        "interproscan.sh",
        "--formats",
        "XML",
        "--input",
        "-",
        "--outfile",
        f"{output}",
        "--cpu",
        f"{cpus}",
        "--tempdir",
        f"{params}",
        "--goterms",
    ]


def tsv_cmd_gen(output):
    return [
        "interproscan.sh",
        "--mode",
        "convert",
        "--formats",
        "TSV",
        "--input",
        f"-",
        "--outfile",
        f"{output}",
        "--goterms",
        "--enable-tsv-residue-annot",
    ]


def Seq2ET(seqs, tmp_faa, tmp_xml, log=None, verbose=False):

    def faa_writer():
        with open(tmp_faa, "w", encoding=ENCODING) as hfaa:
            SeqIO.write(seqs, hfaa, "fasta")

    p = Process(target=faa_writer)
    p.start()

    xml_cmd = xml_cmd_gen(tmp_xml)
    run_log(xml_cmd, tmp_faa, log, verbose)

    p.join()
    return ET.parse(tmp_xml)


if __name__ == "__main__":

    assert INPUT_FAA.exists(), f"File Error: {INPUT_FAA} does NOT exists."

    in_faa = SeqIO.parse(INPUT_FAA, format="fasta")
    tmp_faa = create_fifo(TMP_FAA)
    seq_batch = []
    xmlETs = []

    for idx, seq in enumerate(in_faa):
        seq_batch.append(seq)

        if (idx + 1) % BATCH_SIZE == 0:
            batch_results = Seq2ET(seq_batch, TMP_FAA, TMP_XML, LOG, VERBOSE)
            xmlETs.append(batch_results)
            seq_batch = []

    if len(seq_batch) > 0:
        batch_results = Seq2ET(seq_batch, TMP_FAA, TMP_XML, LOG, VERBOSE)
        xmlETs.append(batch_results)
        seq_batch = []

    merged = merge_ETs(*xmlETs)
    merged.write(OUT_XML, encoding=ENCODING, xml_declaration=True)

    tsv_cmd = tsv_cmd_gen(OUT_TSV)
    run_log(tsv_cmd, OUT_XML, LOG, VERBOSE)

    if CLEAN_TMP:
        TMP_FAA.unlink()
        TMP_XML.unlink()
