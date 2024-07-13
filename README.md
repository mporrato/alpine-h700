# Alpine Linux for the Allwinner H700 SoC

This repository contains a collection of scripts to create a custom Alpine
Linux based SD card image bootable on Allwinner H700 based devices.

In the standard configuration, a very basic system is installed, providing
a login prompt on `/dev/ttyS0`, automatic connection to a WiFi netowk on boot
and an SSH daemon running.

The scripts have been tested on a Fedora Linux 40 system and the generated
image has been tested on an Anbernic RG35XX Plus portable console.

## Requirements

The scripts require the following software:

- `make` (specifically, GNU Make) to orchestrate the build and track
  dependencies
- `python3` to run some of the provided scripts; only modules from the
  standard library are used
- `sgdisk` to manipulate GPT partition tables
- `guestfish` to manipulate filesystem images without root privileges
- `fakeroot` to inject custom configuration files into the rootfs image
  without root privileges
- `podman` to provide an Alpine Linux environment
- `qemu-user-static-aarch64` to enable `podman` to run aarch64 container
  images on a different architecture like x86_64

An image of a stock SD card is required in order to extract components that
are specific to the H700 SoC that do not have open source alternatives yet;
those components are:

- the SPL
- the U-Boot bootloader
- the kernel
- the kernel's modules
- various firmware blobs

## Preparation

### Configuration

Some extra configuration must be provided to connect to a WiFi network and
allow SSH connections.

Anything under the `config` directory will be injected in the rootfs image.

A good staring point would be something like this (replace `$ssid` and
`$password` with the correct network name and password for your WiFi network):

```shell
mkdir -p config/etc/wpa_supplicant
wpa_passphrase '$ssid' '$password' >config/etc/wpa_supplicant/wpa_supplicant.conf
chmod 600 config/etc/wpa_supplicant/wpa_supplicant.conf

mkdir -p config/root/.ssh
cat ~/.ssh/id_*.pub >config/root/.ssh/authorized_keys
chmod 700 config/root config/root/.ssh
```

### Stock SD card image

The scripts expect to find an image of the stock SD card in a file called
`factory.img` in the root of the repository. It can be either an image file or
a link to the actual image file or device, as long as the user running the
scripts has permission to read it. The name of the image can be overridden by
specifying a different path in the `FACTORY_IMAGE` variable when calling the
makefile.

## Usage

To build an image, just run:

```shell
make
```

Or, to use a path to the stock image other than the default:

```shell
make FACTORY_IMAGE=/tmp/RG35XX+-P-V1.1.3-EN16GB-240614.IMG
```

The resulting image will be saved to `./artifacts/alpine-h700.img` and can be
flashed to an SD card, for example, if the card is presented to the system as
`/dev/sde`:

```shell
dd if=artifacts/alpine-h700.img of=/dev/sde bs=1M oflag=dsync status=progress
```

There are other tunable settings: for an exaustive list, see the top of
`Makefile`. Keep in mind that tweaking those values between builds may require
forcing a clean build by issuing a `make clean`.
