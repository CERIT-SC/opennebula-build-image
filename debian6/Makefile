OS=CERIT-SC-Debian
OS_VERSION=6.0
SIZE=11

include ../common.mk

$(IMAGE).raw:
	rm -f $@.tmp
	$(VI) --nographics \
		--initrd-inject=preseed.cfg \
		--initrd-inject=../context/init.debian \
		--location ftp://ftp.debian.org/debian/dists/stable/main/installer-amd64 \
		-x "auto=true priority=critical BOOT_DEBUG=0 DEBIAN_FRONTEND=text preseed/url=file:///preseed.cfg debian-installer/exit/poweroff=true console=tty0 console=ttyS0,115200"
	mv $@.tmp $@
