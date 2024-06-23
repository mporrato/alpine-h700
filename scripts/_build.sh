#!/bin/sh
# This script runs inside an aarch64 alpine linux container and creates a
# base rootfs tarball with wifi support and an ssh daemon active at boot.
set -e

target="$(mktemp -d)"
trap 'rm -rf "$target"' 0

apk update
apk -X "$(awk '/\/alpine\/[^\/]+\/main$/{print;exit}' /etc/apk/repositories)" \
    --keys-dir /etc/apk/keys -U -p "$target/" --initdb \
    add alpine-base alpine-release ca-certificates wpa_supplicant dropbear
cp /etc/apk/repositories "$target/etc/apk/"
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
