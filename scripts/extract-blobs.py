#!/usr/bin/env python3
"""
Extract SPL and U-Boot images from an Allwinner boot image
"""

import argparse
import mmap
from pathlib import Path
import struct
import sys


SPL_SIGNATURE = b"eGON.BT0"
# The SPL can be located at different locations depending on the SoC type
SPL_OFFSETS = [8 * 1024, 128 * 1024, 256 * 1024]
SPL_FILENAME = "spl.img"

UBOOT_SIGNATURE = b"sunxi-package"
UBOOT_OFFSET = 16400 * 1024
UBOOT_FILENAME = "u-boot.img"


class InvalidImageError(Exception):
    pass


def extract_blobs(image: Path, output_dir: Path = Path(), verbose: bool = True):
    with image.open("rb") as f:
        # The first partition starts at 36MB: map all space before that into memory
        mm = mmap.mmap(f.fileno(), 36 * 1024**2, prot=mmap.PROT_READ)
        spl_offset = spl_size = None
        for offset in SPL_OFFSETS:
            sig_offset = offset + 4
            if mm[sig_offset : sig_offset + len(SPL_SIGNATURE)] == SPL_SIGNATURE:
                spl_offset = offset
                (spl_size,) = struct.unpack("<I", mm[offset + 16 : offset + 16 + 4])
                break
        if spl_offset is None:
            raise InvalidImageError("Can't find SPL")
        if verbose:
            print(
                f"Found SPL at offset {spl_offset / 1024}KiB, size {spl_size / 1024}KiB"
            )
        if mm[UBOOT_OFFSET : UBOOT_OFFSET + len(UBOOT_SIGNATURE)] != UBOOT_SIGNATURE:
            raise InvalidImageError("Can't find U-Boot")
        (uboot_size,) = struct.unpack(
            "<I", mm[UBOOT_OFFSET + 36 : UBOOT_OFFSET + 36 + 4]
        )
        if verbose:
            print(
                f"Found U-Boot at offset {UBOOT_OFFSET / 1024}KiB, size {uboot_size / 1024}KiB"
            )
        if not output_dir.exists():
            output_dir.mkdir(mode=0o755, parents=True)
        spl_image = output_dir / SPL_FILENAME
        if verbose:
            print(f"Writing SPL image to {spl_image}")
        spl_image.write_bytes(mm[spl_offset : spl_offset + spl_size])
        uboot_image = output_dir / UBOOT_FILENAME
        if verbose:
            print(f"Writing U-Boot image to {uboot_image}")
        uboot_image.write_bytes(mm[UBOOT_OFFSET : UBOOT_OFFSET + uboot_size])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Extract Allwinner H700 binary blobs from SD card images"
    )
    parser.add_argument("image", type=Path, help="source image or device")
    parser.add_argument(
        "--output", "-o", type=Path, default=Path(), help="output directory"
    )
    parser.add_argument(
        "--verbose", "-v", action="store_true", help="show what's being done"
    )
    args = parser.parse_args()
    try:
        extract_blobs(args.image, args.output, args.verbose)
        sys.exit(0)
    except Exception as e:
        sys.stderr.write(f"{e}\n")
        sys.exit(1)
