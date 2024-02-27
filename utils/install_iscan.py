#!/usr/bin/env python3


from pathlib import Path
import os
import shutil

# dry run
DRY = False

# dependencies
ARIA2C = shutil.which("aria2c")
JAVA = shutil.which("java")

# iscan globals
ISCAN_VERSION = "5.66-98.0"
ISCAN_INSTALLATION_DIR = Path("/usr/share/interproscan")
ISCAN_INSTALLATION_BIN = Path("/usr/bin/interproscan.sh")

# remotes
ISCAN_FTP = f"https://ftp.ebi.ac.uk/pub/databases/interpro/iprscan/5/{ISCAN_VERSION}"
ISCAN_FTP_GZ = f"{ISCAN_FTP}/interproscan-{ISCAN_VERSION}-64-bit.tar.gz"
ISCAN_FTP_MD5 = f"{ISCAN_FTP_GZ}.md5"

# local
MD5 = ISCAN_INSTALLATION_DIR / Path(ISCAN_FTP_MD5).name
GZ = ISCAN_INSTALLATION_DIR / Path(ISCAN_FTP_GZ).name
ISCAN_DIR = ISCAN_INSTALLATION_DIR / f"interproscan-{ISCAN_VERSION}"
ISCAN_BIN = ISCAN_DIR / "interproscan.sh"


def run(cmd: str, dry: bool = False):
    import subprocess as sp
    from shlex import split

    print(f"Running \n{cmd}")

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
    run(f"md5sum -c {MD5}", dry=DRY)

    # untar
    run(f"tar -xf {GZ}", dry=DRY)

    # setup
    if not DRY:
        os.chdir(ISCAN_DIR)
    run(f"python3 setup.py -f interproscan.properties", dry=DRY)

    # create link
    if not DRY:
        ISCAN_INSTALLATION_BIN.symlink_to(ISCAN_BIN)

    # test
    run(f"interproscan.sh -i test_all_appl.fasta -f tsv", dry=DRY)

    # set permissions
    ISCAN_INSTALLATION_DIR.chmod(0o755)
    ISCAN_DIR.chmod(0o755)
