#!/usr/bin/env python3

import os
import shutil
from argparse import ArgumentParser
from pathlib import Path

# iscan defaults
ISCAN_VERSION = "5.67-99.0"
ISCAN_INSTALLATION_DIR = Path("/usr/share/interproscan")
ISCAN_INSTALLATION_BIN = Path("/usr/bin/interproscan.sh")


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
    "--bin",
    type=Path,
    help=f"Where to link the executable to be found by the system. Default: {ISCAN_INSTALLATION_BIN}",
)
parser.add_argument("--skip", action="store_true", help=f"Skip downloading the tar.gz")
parser.add_argument(
    "-n",
    "--dry-run",
    action="store_true",
    help="Do nothing. Only print steps that would be executed.",
)
args = parser.parse_args()


# parse args
ISCAN_VERSION = args.target if args.target is not None else ISCAN_VERSION
ISCAN_INSTALLATION_DIR = args.data if args.data is not None else ISCAN_INSTALLATION_DIR
ISCAN_INSTALLATION_BIN = args.bin if args.bin is not None else ISCAN_INSTALLATION_BIN

DRY = args.dry_run
SKIP = args.skip


# remotes
ISCAN_FTP = f"https://ftp.ebi.ac.uk/pub/databases/interpro/iprscan/5/{ISCAN_VERSION}"
ISCAN_FTP_GZ = f"{ISCAN_FTP}/interproscan-{ISCAN_VERSION}-64-bit.tar.gz"
ISCAN_FTP_MD5 = f"{ISCAN_FTP_GZ}.md5"

# local
MD5 = ISCAN_INSTALLATION_DIR / Path(ISCAN_FTP_MD5).name
GZ = ISCAN_INSTALLATION_DIR / Path(ISCAN_FTP_GZ).name
ISCAN_DIR = ISCAN_INSTALLATION_DIR / f"interproscan-{ISCAN_VERSION}"
ISCAN_BIN = ISCAN_DIR / "interproscan.sh"


# dependencies
ARIA2C = shutil.which("aria2c")
JAVA = shutil.which("java")


def run(cmd: str, dry: bool = False):
    import subprocess as sp
    from shlex import split

    print(f"{cmd}")

    if not dry:
        sp.run(split(cmd), check=True)


if __name__ == "__main__":

    # check dependencies
    if ARIA2C is None or JAVA is None:
        print("Missing aria2c or java binaries")
        print("Execution halted")
        quit()

    # create download directory
    if not DRY:
        ISCAN_INSTALLATION_DIR.mkdir(parents=True, exist_ok=True)

    # download GZ
    if not SKIP:
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
    if not DRY:
        os.chdir(ISCAN_INSTALLATION_DIR)
    else:
        print(f"cd {ISCAN_INSTALLATION_DIR}")

    run(f"md5sum -c {MD5}", dry=DRY)

    # untar
    run(f"tar -xf {GZ}", dry=DRY)

    # setup
    if not DRY:
        os.chdir(ISCAN_DIR)
    else:
        print(f"cd {ISCAN_DIR}")

    run(f"python3 setup.py -f interproscan.properties", dry=DRY)

    # create link
    if not DRY:
        ISCAN_INSTALLATION_BIN.symlink_to(ISCAN_BIN)
    else:
        print(f"ln -s {ISCAN_BIN} {ISCAN_INSTALLATION_BIN.parent}")

    # test
    run(f"interproscan.sh -i test_all_appl.fasta -f tsv", dry=DRY)

    # set permissions
    if not DRY:
        ISCAN_INSTALLATION_DIR.chmod(0o755)
        ISCAN_DIR.chmod(0o755)
    else:
        print(f"chmod 755 {ISCAN_INSTALLATION_DIR}")
        print(f"chmod 755 {ISCAN_DIR}")
