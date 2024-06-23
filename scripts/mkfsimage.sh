#!/bin/bash
# Create a new filesystem and populate it with the specified files.
# Automatically extracts tarballs.
set -e

if [[ $# -lt 5 ]] ; then
	echo "Syntax: $0 IMAGE PART# FSTYPE LABEL SOURCE [...]"
	exit 0
fi

image="$1" ; shift
partition="$1" ; shift
fstype="$1" ; shift
label="$1" ; shift

device="/dev/sda"
[[ $partition -ne 0 ]] && device="$device$partition"

script=(
	"run"
	"mkfs $fstype $device label:$label"
	"mount $device /"
)

while [ $# -gt 0 ] ; do
	src="$1"
	if [[ "$src" =~ .+:.+ ]] ; then
		dest="${src##*:}"
		src="${src%%:*}"
		script+=("mkdir-p \"$dest\"")
	else
		dest="/"
	fi
	if [ -d "$src" ] ; then
		for item in "$src"/* ; do
			cmd="copy-in \"$item\" \"$dest\""
			script+=("$cmd")
		done
	else
		case "$src" in
			*.tar) cmd="tar-in \"$src\" \"$dest\"" ;;
			*.tar.gz) cmd="tar-in \"$src\" \"$dest\" compress:gzip" ;;
			*) cmd="copy-in \"$src\" \"$dest\"" ;;
		esac
		script+=("$cmd")
	fi
	shift
done

script+=("fstrim /")

for cmd in "${script[@]}"; do
	echo "$cmd"
done | guestfish --format=raw -a "$image"
