# Build base OS images for OpenNebula KVM cloud

### Requirements

Installed and configured:

* GNU make
* libvirt and QEMU/KVM
* virt-install
* ONE tools (oneimage)
* disabled SELinux?
* ksvalidator (from pykickstart package)

See [wiki](https://github.com/CERIT-SC/opennebula-build-image/wiki)
for more information.

# Quick Start

Build latest Debian 7:

```bash
$ cd centos7
$ make build
$ make clean
```

Note: upload is prepared for CERIT-SC's administrators.
Just build the image and use your own way how to upload
image (e.g. via browser).

***

CERIT Scientific Cloud, <support@cerit-sc.cz>
