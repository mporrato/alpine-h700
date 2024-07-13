#!/bin/sh
# This script runs inside an aarch64 alpine linux container and creates a
# base rootfs tarball with wifi support and an ssh daemon active at boot.
set -e

target="$(mktemp -d)"
trap 'rm -rf "$target"' 0

apk update
apk -X "$(awk '/\/alpine\/[^\/]+\/main$/{print;exit}' /etc/apk/repositories)" \
    --keys-dir /etc/apk/keys -U -p "$target/" --initdb \
    add alpine-base alpine-release ca-certificates wpa_supplicant dropbear dropbear-scp
cp /etc/apk/repositories "$target/etc/apk/"
cat >"$target/etc/motd" <<__EOF__
Welcome to Alpine!

This is an unofficial port to the Allwinner H700 SoC: please report
issues to https://github.com/mporrato/alpine-h700 .

The Alpine Wiki contains a large amount of how-to guides and general
information about administrating Alpine systems.
See <https://wiki.alpinelinux.org/>.

You may change this message by editing /etc/motd.

__EOF__
echo "nameserver 8.8.8.8" >"$target/etc/resolv.conf"
sed -Ei 's/^(tty[0-9]+:)/#\1/;s/^#ttyS0:/ttyS0:/' "$target/etc/inittab"
echo h700 >"$target/etc/hostname"
echo 8821cs >"$target/etc/modules"
cat >"$target/etc/network/interfaces" <<__EOF__
auto lo
iface lo inet loopback

auto wlan0
iface wlan0 inet dhcp
__EOF__
for svc in devfs dmesg mdev ; do
    chroot "$target" rc-update add "$svc" sysinit
done
for svc in hwclock modules sysctl hostname bootmisc syslog wpa_supplicant networking ; do
    chroot "$target" rc-update add "$svc" boot
done
for svc in mount-ro killprocs savecache ; do
    chroot "$target" rc-update add "$svc" shutdown
done
chroot "$target" rc-update add dropbear default

tar cf "${1:-/tmp/rootfs.tar}" -C "$target" .
