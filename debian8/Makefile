OS=CERIT-SC-Debian
OS_VERSION=8
OS_CODE=jessie

include ../common.mk

$(IMAGE).raw: preseed.cfg cloud.cfg
	rm -f $@.tmp
	$(VI) --nographics \
		$(patsubst %,--initrd-inject=%, $?) \
		--location ftp://ftp.debian.org/debian/dists/$(OS_CODE)/main/installer-amd64 \
		-x "console=tty0 console=ttyS0,115200 auto=true priority=critical BOOT_DEBUG=0 DEBIAN_FRONTEND=text preseed/url=file:///preseed.cfg debian-installer/exit/poweroff=true"
	mv $@.tmp $@
