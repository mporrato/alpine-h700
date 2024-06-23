#!/bin/bash
# Assemble SPL, U-Boot, U-Boot environment, boot-resources, boot and rootfs
# images into a final H700 bootable sdcard image.
set -e

if [[ $# -lt 7 ]] ; then
	echo "Usage: $0 SDCARD SPL UBOOT ENV BOOT-RESOURCE BOOT ROOTFS"
	exit 0
fi

mb() {
	# Return the file size in MiB (rounded up)
	local file_size
	file_size="$(stat -c "%s" "$1")"
	echo "$(( (file_size + 1024 ** 2 - 1) / 1024 ** 2 ))M"
}

sgdisk --move-main-table=73696 -I \
    --new="0:0:+$(mb "$4")" --change-name=0:env           --attributes=0:=:c000000000000001 --typecode=0:b000 \
    --new="0:0:+$(mb "$5")" --change-name=0:boot-resource --attributes=0:=:c000000000000001 --typecode=0:0700 \
    --new="0:0:+$(mb "$6")" --change-name=0:boot          --attributes=0:=:c000000000000001 --typecode=0:a002 \
    --new="0:0:+$(mb "$7")" --change-name=0:rootfs        --attributes=0:=:c000000000000001 --typecode=0:8305 \
    "$1"

part_table="$(sgdisk -p artifacts/alpine-h700.img | awk '/^ +[0-9]+ +[0-9]+ +[0-9]+/{print $2 / 2}' | xargs)"
read -r -a offsets <<<"$part_table"

images=("$2" "$3" "$4" "$5" "$6" "$7")
offsets=(8 16400 "${offsets[@]}")

for i in "${!images[@]}"; do
	img="${images[$i]}"
	off="${offsets[$i]}"
	echo "Writing $img at offset ${off}KiB"
	dd if="$img" of="$1" bs=1K seek="${off}" conv=sparse,notrunc status=none
done
echo "Your bootable SD image is $1"