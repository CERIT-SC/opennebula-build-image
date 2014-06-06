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
	--console pty \
	--connect $(LIBVIRT_URI) \
	--name="$(VI_NAME)" \
	--ram=$(VI_RAM) \
	--vcpus=$(VI_CPU) \
	--wait=$(VI_TIMEOUT) \
	--disk path=$@.tmp,format=raw,size=$(SIZE),cache=unsafe,sparse=true,bus=virtio \
	--network=user,model=virtio \
	--network=user,model=virtio \
	--video=vga \
	--noreboot
VI_NAME?=build-$(ON_PREFIX)
VI_CPU?=2
VI_RAM?=1536
VI_TIMEOUT?=45

# qemu-image
IMAGE?=$(CURDIR)/image
QI_QCOW_OPTS?=-c -o cluster_size=2M
QI_VMDK_OPTS?=

# ON ... OpenNebula image
ON_DS?=cerit-sc-zegox cerit-sc-ha-brno cerit-sc-ha-jihlava cerit-sc-zigur_zapat
ON_PUBLIC_DS?=cerit-sc-cloud

ON_PREFIX?=$(OS)-$(OS_VERSION)
ON_NAME?=$(ON_PREFIX)-$(ON_VERSION)
ON_DESCRIPTION?=Generic OS image by CERIT Scientific Cloud
ON_VERSION:=$(shell date +%Y%m%d%H%M)
ON_SOURCE?=$(shell oneimage show $(ON_NAME) | awk -F'[ ]*:[ ]*' '$$1=="SOURCE" { print $$2 }')
ON_DEV_PREFIX?=vd
ON_PERSISTENT?=no
ON_OWNER?=cerit-sc-admin
ON_GROUP?=cerit-sc

# ON upload variables
SCP_HOST?=cerit-sc-admin-api@carach4.ics.muni.cz
SCP_PATH?=/home/cerit-sc-admin-api

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
	nice ionice -c 3 qemu-img convert $(QI_QCOW_OPTS) -O qcow2 $? $@

# convert raw->vmdk
$(IMAGE).vmdk: $(IMAGE).raw
	nice ionice -c 3 qemu-img convert $(QI_VMDK_OPTS) -O vmdk $? $@

## upload image to default datastore through OCCI
#$(ON_NAME): $(IMAGE).$(FORMAT)
#	if ! oneimage show $(ON_NAME); then \
#		set -e; \
#		DEF=`mktemp`; \
#		m4 -D__NAME__="$(ON_NAME)" \
#			-D__DESCRIPTION__="$(ON_DESCRIPTION)" \
#			-D__URL__="file://$?" \
#			$(M4_OCCI_STORAGE) | tee $$DEF; \
#		occi-storage create $$DEF; \
#		unlink $$DEF; \
#	fi

# upload image to ON server
$(ON_NAME): $(IMAGE).$(FORMAT)
	scp -o 'Compression no' -o 'Cipher blowfish' \
		$? $(SCP_HOST):$(SCP_PATH)/$(ON_NAME).$(FORMAT)

## copy image from default to specified datastore
#$(ON_NAME)@%: $(ON_NAME)
#	if ! oneimage show $@; then \
#		set -e; \
#		DEF=`mktemp`; \
#		m4 -D__NAME__="$@" \
#			-D__DESCRIPTION__="$(ON_DESCRIPTION)" \
#			-D__PATH__="$(ON_SOURCE)" \
#			-D__DRIVER__="$(ON_DRIVER)" \
#			-D__DEV_PREFIX__="$(ON_DEV_PREFIX)" \
#			-D__PERSISTENT__="$(ON_PERSISTENT)" \
#			$(M4_ONEIMAGE) | tee $$DEF; \
#		oneimage create $$DEF --datastore $*; \
#		oneimage chgrp "$@" $(ON_GROUP) ; \
#		oneimage chmod "$@" $(ON_MODE) ; \
#		unlink $$DEF; \
#	fi

#define oneimage
#	oneimage create -v --name "$1" \
#		--source="$(SCP_PATH)/$(ON_NAME).$(FORMAT)" \
#		--prefix=vd --type=OS  --driver=$(FORMAT) \
#		--datastore="$2" --disk_type="BLOCK" \
#		--size=$$(($(SIZE) * 1024)) \
#		--description="$(ON_DESCRIPTION)"
#	oneimage chown "$1" $(ON_OWNER)
#	oneimage chgrp "$1" $(ON_GROUP)
#	oneimage chmod "$1" $3
#endef

define oneimage 
	set -e; \
	DEF=`mktemp`; \
	m4 -D__NAME__="$1" \
		-D__DESCRIPTION__="$(ON_DESCRIPTION)" \
		-D__PATH__="$(SCP_PATH)/$(ON_NAME).$(FORMAT)" \
		-D__DRIVER__="$(FORMAT)" \
		-D__DEV_PREFIX__="$(ON_DEV_PREFIX)" \
		-D__PERSISTENT__="$(ON_PERSISTENT)" \
		$(M4_ONEIMAGE) | tee $$DEF; \
	oneimage create $$DEF --datastore $2; \
	oneimage chown "$1" $(ON_OWNER) ; \
	oneimage chgrp "$1" $(ON_GROUP) ; \
	oneimage chmod "$1" $3 ; \
	unlink $$DEF
endef

#$(ON_NAME)@%: $(ON_NAME)
#	oneimage create -v --name "$@" \
#		--source="$(ON_PATH)/$(ON_NAME).$(FORMAT)" \
#		--prefix=vd --type=OS  --driver=$(FORMAT) \
#		--datastore="$*" --disk_type="BLOCK" \
#		--size=$$(($(SIZE) * 1024)) \
#		--description="Generic OS image by CERIT Scientific Cloud"
#	oneimage chown "$@" $(ON_OWNER)
#	oneimage chgrp "$@" $(ON_GROUP)
#	oneimage chmod "$@" $(ON_MODE)

$(ON_NAME)@%: $(ON_NAME)
	$(call oneimage,$@,$*,600)

$(ON_NAME)@%.public: $(ON_NAME)
	$(call oneimage,$(ON_NAME)@$*,$*,644)

upload: \
		$(patsubst %, $(ON_NAME)@%.public, $(ON_PUBLIC_DS)) \
		$(patsubst %, $(ON_NAME)@%, $(ON_DS))

empty:
	echo -n >empty

clean: empty
	-virsh -q -c $(LIBVIRT_URI) destroy  $(VI_NAME) 2>/dev/null
	-virsh -q -c $(LIBVIRT_URI) undefine $(VI_NAME) 2>/dev/null 
#	-oneimage delete $(ON_NAME)
	-scp -o 'Compression no' -o 'Cipher blowfish' \
		empty $(SCP_HOST):$(SCP_PATH)/$(ON_NAME).$(FORMAT)
	rm -f $(IMAGE).raw $(IMAGE).raw.tmp $(IMAGE).$(FORMAT) \
		$(IMAGE).qcow2 $(IMAGE).vmdk cloud.tar empty
