#!/bin/bash
# Extracts kernel modules and firmware blobs from the given
# rootfs image.
set -e

if [[ $# -lt 2 ]] ; then
	echo "Syntax: $0 IMAGE OUTDIR [PARTNO]"
	exit 0
fi

image="$1"
outdir="$2"
partno="${3:-5}"

device="/dev/sda$partno"

guestfish --ro --format=raw -a "$image" <<__EOF__
run
mount "$device" /
tar-out /lib/modules "$outdir/modules.tar"
tar-out /lib/firmware "$outdir/firmware.tar"
__EOF__
