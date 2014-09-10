# Image build scripts for CERIT-SC's OpenNebula KVM cloud

### Requirements

Installed and configured:

* GNU make
* libvirt and QEMU/KVM
* virt-install
* ONE tools (oneimage)
* disabled SELinux?

See [wiki](wiki/) for more information.

# Quick Start

Build and upload new/updated Debian 7:

```bash
$ cd debian7
$ make build upload clean
```

Note: upload is prepared for CERIT-SC's administrators.
Just build the image and use your own way how to upload
image (e.g. via browser).

***

CERIT Scientific Cloud, <support@cerit-sc.cz>
