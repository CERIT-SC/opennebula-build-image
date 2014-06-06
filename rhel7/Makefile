OS=CERIT-SC-RHEL
OS_VERSION=7
ON_DS=
ON_PUBLIC_DS=cerit-sc-cloud

include ../common.mk

.PHONY: FORCE

FORCE:

%.ks:
	ksvalidator -v RHEL7 $@

$(IMAGE).raw: rhel.ks cloud.cfg ../RPM-GPG-KEY-EPEL-7.cfg ../RPM-GPG-KEY-CERIT-SC.cfg
	rm -f $@.tmp
	$(VI) --nographics \
		--os-variant=rhel7 \
		$(patsubst %,--initrd-inject=%, $?) \
		--location http://ftp.linux.cz/pub/linux/redhat/rhel/rc/7/Server/x86_64/os/ \
		-x "elevator=deadline console=tty0 console=ttyS0,115200 inst.ks=file:/rhel.ks inst.cmdline RUNKS=1 inst.loglevel=debug" && echo OK
	mv $@.tmp $@

