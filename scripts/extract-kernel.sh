#!/bin/bash
# Extract the kernel and boot image configuration from the given
# android boot image.
set -e

image="$1"
outdir="${2:-./artifacts}"

boot_part="$(sgdisk -p "$image" | awk '$7=="boot"{print $2 " " $3-$2+1;exit}')"
read -r -a boot <<<"$boot_part"

block_shift="$(factor -h "${boot[@]}" | grep -Eo "2\^[0-9]+" | sed 's/^2\^//' | sort -n | head -n1)"
block_size="$((2 ** block_shift))"
start_blocks="$((boot[0] / block_size))"
size_blocks="$((boot[1] / block_size))"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' 0

dd if="$image" of="$tmp/boot.img" bs="$((512 * block_size))" skip="$start_blocks" count="$size_blocks" conv=sparse status=none
abootimg -x "$tmp/boot.img" "$outdir/bootimg.cfg" "$outdir/zImage" /dev/null /dev/null
