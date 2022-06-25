PREFIX = perdita
DEFCONFIG = ../br2perdita/configs/perdita_defconfig
DEFCONFIG_RESCUE = ../br2perdita/configs/perdita_rescue_defconfig
EXTERNALS +=../br2autosshkey ../br2sanetime ../br2chenxing ../br2dgppkg ../br2perdita ../br2games ../br2directfb2 ../br2dgprescue
TOOLCHAIN = arm-buildroot-linux-gnueabihf_sdk-buildroot.tar.gz

all: buildroot-dl buildroot buildroot-rescue copy_outputs upload

bootstrap.stamp:
	git submodule init
	git submodule update
	touch bootstrap.stamp

./br2secretsauce/common.mk: bootstrap.stamp
./br2secretsauce/rescue.mk: bootstrap.stamp
./br2secretsauce/ubi.mk: bootstrap.stamp

bootstrap: bootstrap.stamp

include ./br2secretsauce/common.mk
include ./br2secretsauce/rescue.mk
include ./br2secretsauce/ubi.mk

.PHONY: ubi.img

gcis.bin:
	$(BUILDROOT_PATH)/output/host/bin/mstar_gcistool --bl0pba 1 --bl1pba 2 --outfile $@

ubi.img:
	- rm ubinize.cfg.tmp
	dd if=/dev/zero bs=1024 count=256 | tr '\000' '\377' > env.img
	$(call ubi-add-vol,0,uboot,1MiB,static,$(BUILDROOT_PATH)/output/images/u-boot.img)
	$(call ubi-add-vol,1,env,256KiB,static,env.img)
	$(call ubi-add-vol,2,kernel,16MiB,static,$(BUILDROOT_PATH)/output/images/kernel.fit)
	$(call ubi-add-vol,3,rootfs,64MiB,dynamic,$(BUILDROOT_PATH)/output/images/rootfs.squashfs)
	$(call ubi-add-vol,4,rescue,16MiB,static,$(BUILDROOT_RESCUE_PATH)/output/images/rescue.fit)
	/usr/sbin/ubinize -o $@ -p 128KiB -m 2048 -s 2048 ubinize.cfg.tmp

flash.bin: gcis.bin
	dd if=/dev/zero bs=1K count=384 | tr '\000' '\377' > $@
	dd if=gcis.bin of=$@ conv=notrunc
	dd if=buildroot/output/images/ipl of=$@ seek=128 bs=1K conv=notrunc
	dd if=buildroot/output/images/ipl of=$@ seek=256 bs=1K conv=notrunc
	cat ubi.img >> $@

copy_outputs: ubi.img gcis.bin
	cp buildroot/output/images/ipl $(OUTPUTS)/$(PREFIX)-ipl
	cp buildroot/output/images/u-boot.img $(OUTPUTS)/$(PREFIX)-u-boot.img
	cp buildroot/output/images/kernel.fit $(OUTPUTS)/$(PREFIX)-kernel.fit
	cp buildroot/output/images/rootfs.squashfs $(OUTPUTS)/$(PREFIX)-rootfs.squashfs
	cp buildroot_rescue/output/images/rescue.fit $(OUTPUTS)/$(PREFIX)-rescue.fit
	$(call copy_to_outputs, ubi.img)
	$(call copy_to_outputs, gcis.bin)

upload:
	$(call upload_to_tftp_with_scp,$(BUILDROOT_PATH)/output/images/ipl)
	$(call upload_to_tftp_with_scp,$(BUILDROOT_PATH)/output/images/u-boot.img)
	$(call upload_to_tftp_with_scp,$(BUILDROOT_PATH)/output/images/kernel.fit)
	$(call upload_to_tftp_with_scp,$(BUILDROOT_PATH)/output/images/rootfs.squashfs)
	$(call upload_to_tftp_with_scp,$(BUILDROOT_RESCUE_PATH)/output/images/rescue.fit)
