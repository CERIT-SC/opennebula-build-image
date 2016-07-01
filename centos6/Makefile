OS=CERIT-SC-CentOS
OS_VERSION=6

include ../common.mk

.PHONY: FORCE

FORCE:

%.ks: FORCE
	ksvalidator -v RHEL6 $@

$(IMAGE).raw: centos.ks cloud.cfg ../RPM-GPG-KEY-EPEL-6.cfg
	rm -f $@.tmp
	$(VI) --nographics \
		--os-variant=rhel6 \
		$(patsubst %,--initrd-inject=%, $?) \
		--location http://ftp.linux.cz/pub/linux/centos/6/os/x86_64/ \
		-x "elevator=deadline console=tty0 console=ttyS0,115200 vga=normal loglevel=debug cmdline serial ks=file:/centos.ks"
	mv $@.tmp $@
