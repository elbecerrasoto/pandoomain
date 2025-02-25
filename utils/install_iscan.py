#!/usr/bin/env python3

import shutil
import subprocess as sp
import sys
from argparse import ArgumentParser
from pathlib import Path
from shlex import split
from warnings import warn


def run(cmd: str, dry: bool = False, **kwargs):
    try:
        print(f"cd {kwargs['cwd']}")
    except KeyError:
        pass

    print(f"{cmd}")

    if not dry:
        sp.run(split(cmd), check=True, **kwargs)


def can_reach(url):
    """
    https://stackoverflow.com/questions/16778435/python-check-if-website-exists
    """
    import httplib2

    try:
        h = httplib2.Http()
        resp = h.request(url, "HEAD")
        return int(resp[0]["status"]) < 400
    except httplib2.ServerNotFoundError:
        return False


# iscan defaults
ISCAN_VERSION = "5.73-104.0"
ISCAN_INSTALLATION_DIR = Path(".")


# define args
parser = ArgumentParser(description="Download and Install interproscan.sh")

parser.add_argument(
    "--target", help=f"Version interproscan.sh to install. Default: {ISCAN_VERSION}"
)
parser.add_argument(
    "--data",
    type=Path,
    help=f"Where to put the profile data. About 60GB. Default: {ISCAN_INSTALLATION_DIR}",
)
parser.add_argument(
    "-n",
    "--dry-run",
    action="store_true",
    help="Do nothing. Only print steps that would be executed.",
)
args = parser.parse_args()


# parse args
ISCAN_VERSION = args.target if args.target is not None else ISCAN_VERSION
ISCAN_INSTALLATION_DIR = (
    args.data if args.data is not None else ISCAN_INSTALLATION_DIR
).resolve()
DRY = args.dry_run

# remotes
ISCAN_FTP = f"https://ftp.ebi.ac.uk/pub/databases/interpro/iprscan/5/{ISCAN_VERSION}"
ISCAN_FTP_GZ = f"{ISCAN_FTP}/interproscan-{ISCAN_VERSION}-64-bit.tar.gz"
ISCAN_FTP_MD5 = f"{ISCAN_FTP_GZ}.md5"

# local
MD5 = (ISCAN_INSTALLATION_DIR / Path(ISCAN_FTP_MD5).name).resolve()
GZ = (ISCAN_INSTALLATION_DIR / Path(ISCAN_FTP_GZ).name).resolve()
ISCAN_DIR = (ISCAN_INSTALLATION_DIR / f"interproscan-{ISCAN_VERSION}").resolve()
ISCAN_BIN = (ISCAN_DIR / "interproscan.sh").resolve()


# dependencies
ARIA2C = shutil.which("aria2c")
JAVA = shutil.which("java")


if __name__ == "__main__":

    # check network
    for url in (ISCAN_FTP_GZ, ISCAN_FTP_MD5):
        if not can_reach(url):
            raise ConnectionError(f"Unreachable {url}")

    # check dependencies
    if ARIA2C is None or JAVA is None:
        print("Missing aria2c or java binaries")
        print("Execution halted")
        sys.exit(1)

    # create download directory
    if DRY:
        print("\n# Create download directory.")
        print(f"mkdir -p {ISCAN_INSTALLATION_DIR}")
    else:
        ISCAN_INSTALLATION_DIR.mkdir(parents=True, exist_ok=True)

    # download GZ
    if DRY:
        print("\n# Download GZ.")
    for ftp_target in (ISCAN_FTP_MD5, ISCAN_FTP_GZ):
        cmd = (
            "aria2c "
            f"--dir {ISCAN_INSTALLATION_DIR} "
            "--continue=true "
            "--split 12 "
            "--max-connection-per-server=16 "
            "--min-split-size=1M "
            f"{ftp_target}"
        )
        run(cmd, dry=DRY)

    # check md5sum
    if DRY:
        print("\n# Check md5sum.")
    run(f"md5sum -c {MD5}", dry=DRY, cwd=ISCAN_INSTALLATION_DIR)

    # untar
    if DRY:
        print("\n# Untar.")
    run(f"tar -xf {GZ}", dry=DRY, cwd=ISCAN_INSTALLATION_DIR)

    # setup
    if DRY:
        print("\n# Setup profiles.")
    run(f"python3 setup.py -f interproscan.properties", dry=DRY, cwd=ISCAN_DIR)

    # set permissions
    if not DRY:
        ISCAN_BIN.chmod(0o755)
    else:
        print("\n# Set premissions.")
        print(f"chmod 755 {ISCAN_BIN}")

    # test
    if DRY:
        print("\n# Test installation.")
    run(f"{ISCAN_BIN} -i test_all_appl.fasta -f tsv", dry=DRY, cwd=ISCAN_DIR)
