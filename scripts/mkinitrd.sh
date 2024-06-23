#!/bin/bash

podman run --arch=arm64 --security-opt=label=disable \
	-v "${2:-./artifacts}:/artifacts" \
	-v ./mkinitfs.conf:/tmp/mkinitfs.conf:ro \
	--rm "docker.io/library/alpine:${1:-latest}" \
	sh -c "apk update && apk add mkinitfs apk-tools && mkinitfs -c /tmp/mkinitfs.conf -n -o /artifacts/initramfs"
