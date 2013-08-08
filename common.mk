# defaults
FORMAT?=qcow2
SIZE?=10
ROOT_PASSWORD:=$(shell dd if=/dev/urandom bs=1 count=64 2>/dev/null | base64 | awk "{printf \$$0}")

# Libvirt/virt-install variables
#LIBVIRT_URI?=qemu:///system
LIBVIRT_URI?=qemu:///session 

# virt-install
VI?=virt-install \
	--force \
	--connect $(LIBVIRT_URI) \
	--name="$(VI_NAME)" \
	--ram=$(VI_RAM) \
	--vcpus=$(VI_CPU) \
	--wait=$(VI_TIMEOUT) \
	--disk path=$@.tmp,format=raw,size=$(SIZE),bus=virtio \
	--network=user,model=virtio \
	--network=user,model=virtio \
	--watchdog default \
	--video=vga \
	--noreboot
VI_NAME?=build-$(ON_PREFIX)
VI_CPU?=2
VI_RAM?=1024
VI_TIMEOUT?=45

# qemu-image
IMAGE?=$(CURDIR)/image
QI_QCOW_OPTS?=-c -o cluster_size=2M
QI_VMDK_OPTS?=

# ON ... OpenNebula image
ON_DATA_STORES?=cerit-sc-zegox cerit-sc-cloud cerit-sc-ha-jihlava cerit-sc-zigur_zapat
ON_PREFIX?=$(OS)-$(OS_VERSION)
ON_NAME?=$(ON_PREFIX)-$(ON_VERSION)
ON_DESCRIPTION?=OpenNebula Image
ON_VERSION:=$(shell oneimage list -x 2>/dev/null | egrep -xi '\s*<NAME>$(ON_PREFIX)-[0-9]+[^<]+</NAME>\s*' | sed -e 's/\s*<NAME>$(ON_PREFIX)-\([0-9]*\)[^<]*<\/NAME>\s*/\1/' | awk 'BEGIN{max=0} {if ($$0>max) max=$$0} END{printf "%04i",max+1}')
ON_SOURCE?=$(shell oneimage show $(ON_NAME) | awk -F'[ ]*:[ ]*' '$$1=="SOURCE" { print $$2 }')
ON_DEV_PREFIX?=vd
ON_DRIVER?=qcow2
ON_PERSISTENT?=no
ON_GROUP?=cerit-sc
ON_MODE?=644

# M4 templates
M4_OCCI_STORAGE?=../occi-storage.m4
M4_ONEIMAGE?=../oneimage.m4

###################################################

all: build upload clean

build: $(IMAGE).$(FORMAT)

cloud.tar: cloud/
	tar -cvf $@ $?

# convert raw->qcow2
$(IMAGE).qcow2: $(IMAGE).raw
	qemu-img convert $(QI_QCOW_OPTS) -O qcow2 $? $@

# convert raw->vmdk
$(IMAGE).vmdk: $(IMAGE).raw
	qemu-img convert $(QI_VMDK_OPTS) -O vmdk $? $@

# upload image to default datastore through OCCI
$(ON_NAME): $(IMAGE).$(FORMAT)
	if ! oneimage show $(ON_NAME); then \
		set -e; \
		DEF=`mktemp`; \
		m4 -D__NAME__="$(ON_NAME)" \
			-D__DESCRIPTION__="$(ON_DESCRIPTION)" \
			-D__URL__="file://$?" \
			$(M4_OCCI_STORAGE) | tee $$DEF; \
		occi-storage create $$DEF; \
		unlink $$DEF; \
	fi

# copy image from default to specified datastore
$(ON_NAME)@%: $(ON_NAME)
	if ! oneimage show $@; then \
		set -e; \
		DEF=`mktemp`; \
		m4 -D__NAME__="$@" \
			-D__DESCRIPTION__="$(ON_DESCRIPTION)" \
			-D__PATH__="$(ON_SOURCE)" \
			-D__DRIVER__="$(ON_DRIVER)" \
			-D__DEV_PREFIX__="$(ON_DEV_PREFIX)" \
			-D__PERSISTENT__="$(ON_PERSISTENT)" \
			$(M4_ONEIMAGE) | tee $$DEF; \
		oneimage create $$DEF --datastore $*; \
		oneimage chgrp "$@" $(ON_GROUP) ; \
		oneimage chmod "$@" $(ON_MODE) ; \
		unlink $$DEF; \
	fi

upload: $(patsubst %, $(ON_NAME)@%, $(ON_DATA_STORES))

clean: 
	-virsh -q -c $(LIBVIRT_URI) destroy  $(VI_NAME) 2>/dev/null
	-virsh -q -c $(LIBVIRT_URI) undefine $(VI_NAME) 2>/dev/null 
	-oneimage delete $(ON_NAME)
	rm -f $(IMAGE).raw $(IMAGE).raw.tmp $(IMAGE).$(FORMAT) \
		$(IMAGE).qcow2 $(IMAGE).vmdk cloud.tar
