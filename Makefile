.PHONY: sdcard images clean

A=./artifacts
C=./config
R=./resources
S=./scripts

#############################################################################
# Tunable parameters are in this section
ALPINE_VERSION?=latest
FACTORY_IMAGE?=factory.img
SD_SIZE?=250M
RESOURCES_SIZE?=8M
ROOTFS_SIZE?=100M
#############################################################################

SPL=$(A)/spl.img
UBOOT=$(A)/u-boot.img
ENV=$(A)/env.img
RESOURCES=$(A)/boot-resources.img
BOOT=$(A)/boot.img
BOOTCFG=$(A)/bootimg.cfg
KERNEL=$(A)/zImage
INITRD=$(A)/initramfs
FIRMWARE_TAR=$(A)/firmware.tar
MODULES_TAR=$(A)/modules.tar
ROOTFS_TAR=$(A)/rootfs.tar
CONFIG_TAR=$(A)/config.tar
ROOTFS=$(A)/rootfs.img
IMAGES=$(SPL) $(UBOOT) $(ENV) $(RESOURCES) $(BOOT) $(ROOTFS)
SD=$(A)/alpine-h700.img

sdcard: $(SD)

images: $(IMAGES)

$(SD): $(IMAGES)
	$(RM) $@
	truncate -s $(SD_SIZE) $@
	$(S)/mkpart.sh $@ $^

$(SPL) $(UBOOT): $(FACTORY_IMAGE)
	$(S)/extract-blobs.py $^ -o $(A)

$(ENV): env.txt
	$(S)/mkenv.py $^ $@

$(BOOT): $(BOOTCFG) $(KERNEL) $(INITRD)
	abootimg --create $@ -f $(BOOTCFG) -k $(KERNEL) -r $(INITRD)

$(KERNEL) $(BOOTCFG): $(FACTORY_IMAGE)
	$(S)/extract-kernel.sh $^ $(A)

$(INITRD):
	$(S)/mkinitrd.sh $(ALPINE_VERSION)

$(RESOURCES): $(shell find $(R) -type f -print0 | xargs -0)
	$(RM) $@
	truncate -s $(RESOURCES_SIZE) $@
	$(S)/mkfsimage.sh $@ 0 vfat resources $(R)

$(ROOTFS_TAR):
	$(S)/build-rootfs.sh $(ALPINE_VERSION) $(A)

$(FIRMWARE_TAR) $(MODULES_TAR): $(FACTORY_IMAGE)
	$(S)/extract-modules.sh $< $(A)

$(CONFIG_TAR): $(shell find $(C) -type f -print0 | xargs -0)
	date --utc "+%Y-%m-%dT%H:%M:%SZ" >$(C)/.build
	fakeroot -- tar cf $@ --exclude .gitkeep -C $(C) .

$(ROOTFS): $(ROOTFS_TAR) $(FIRMWARE_TAR) $(MODULES_TAR) $(CONFIG_TAR)
	$(RM) $@
	truncate -s $(ROOTFS_SIZE) $@
	$(S)/mkfsimage.sh $@ 0 ext4 rootfs $(ROOTFS_TAR) $(FIRMWARE_TAR):/lib/firmware/ $(MODULES_TAR):/lib/modules/ $(CONFIG_TAR)

clean:
	$(RM) $(A)/*
