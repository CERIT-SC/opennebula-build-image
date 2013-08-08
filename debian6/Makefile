OS=CERIT-SC-Debian
OS_VERSION=6.0
OS_CODE=squeeze
SIZE=11

include ../common.mk

$(IMAGE).raw: preseed.cfg cloud.tar ../cloud-init/cloud-init-$(OS_CODE).deb
	rm -f $@.tmp
	$(VI) --nographics \
		$(patsubst %,--initrd-inject=%, $?) \
		--location ftp://ftp.debian.org/debian/dists/$(OS_CODE)/main/installer-amd64 \
		-x "elevator=deadline console=tty0 console=ttyS0,115200 auto=true priority=critical BOOT_DEBUG=0 DEBIAN_FRONTEND=text preseed/url=file:///preseed.cfg debian-installer/exit/poweroff=true"
	mv $@.tmp $@
