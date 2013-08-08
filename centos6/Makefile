OS=CERIT-SC-CentOS
OS_VERSION=6
SIZE=10

include ../common.mk

$(IMAGE).raw: centos.ks cloud.tar ../cloud-init/cloud-init-el6.rpm
	rm -f $@.tmp
	$(VI) --nographics \
		--os-variant=rhel6 \
		$(patsubst %,--initrd-inject=%, $?) \
		--location http://ftp.linux.cz/pub/linux/centos/6/os/x86_64/ \
		-x "elevator=deadline console=tty0 console=ttyS0,115200 vga=normal loglevel=debug cmdline serial ks=file:/centos.ks"
	mv $@.tmp $@

