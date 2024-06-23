#!/bin/bash

podman run --arch=aarch64 --security-opt=label=disable \
	-v "${2:-./artifacts}:/artifacts" \
	-v ./scripts/_build.sh:/usr/local/bin/_build.sh \
	--rm "docker.io/library/alpine:${1:-latest}" \
	sh /usr/local/bin/_build.sh /artifacts/rootfs.tar
