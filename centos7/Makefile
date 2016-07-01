OS=CERIT-SC-CentOS
OS_VERSION=7

include ../common.mk

.PHONY: FORCE

FORCE:

%.ks:
	ksvalidator -v RHEL7 $@

$(IMAGE).raw: centos.ks cloud.cfg ../RPM-GPG-KEY-EPEL-7.cfg
	rm -f $@.tmp
	$(VI) --nographics \
		--os-variant=rhel7 \
		$(patsubst %,--initrd-inject=%, $?) \
		--location http://ftp.linux.cz/pub/linux/centos/7/os/x86_64/ \
		-x "elevator=deadline console=tty0 console=ttyS0,115200 inst.ks=file:/centos.ks inst.cmdline RUNKS=1 inst.loglevel=debug" && echo OK
	mv $@.tmp $@

