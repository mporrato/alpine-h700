#!/usr/bin/env python3
"""
Create a U-Boot environment image from a text environment file

This is required because the Anbernic environment format is not compatible
with the binary format produced by the mkenvimage tool from the uboot-tools
package
"""

import argparse
import struct
import sys
import zlib


ENCODING = "utf-8"
DEFAULT_IMG_SIZE = 128 * 1024
DEFAULT_IMG_FLAGS = 0


class EnvError(Exception):
    pass


def makebinenv(infile, outfile, size, flags):
    """
    Create a U-Boot environment image from a text environment file
    """

    buf = b""
    for line in infile:
        clean_line = line.strip()
        if clean_line and not clean_line.startswith("#"):
            buf += bytes(clean_line, ENCODING) + b"\0"
    infile.close()
    buf += b"\0"
    if flags is not None:
        buf = bytes([flags]) + buf
    envsize = 4 + len(buf)
    if envsize > size:
        raise EnvError(f"Insufficient environment space: need at least {envsize} bytes")
    buf += bytes(size - envsize)
    crc = zlib.crc32(buf, 0)
    buf = struct.pack("<I", crc) + buf
    outfile.write(buf)
    outfile.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="mkenv.py",
        description=(
            "Create an Anbernic U-Boot environment image from a text environment file"
        ),
    )
    parser.add_argument(
        "textfile",
        type=argparse.FileType("r", encoding=ENCODING),
        help="input text environment file",
    )
    parser.add_argument(
        "binfile",
        type=argparse.FileType("wb"),
        help="output binary environment image file",
    )
    parser.add_argument(
        "-s",
        "--size",
        type=int,
        default=DEFAULT_IMG_SIZE,
        help=(f"size of the output binary image in bytes (default={DEFAULT_IMG_SIZE})"),
    )
    parser.add_argument(
        "-f",
        "--flags",
        type=int,
        default=0,
        help=f"binary image flags (default={DEFAULT_IMG_FLAGS})",
    )
    args = parser.parse_args()

    try:
        makebinenv(args.textfile, args.binfile, args.size, args.flags)
        sys.exit(0)
    except Exception as e:
        sys.stderr.write(f"{e}\n")
        sys.exit(1)
