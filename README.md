# Image build scripts for CERIT-SC's OpenNebula KVM cloud

### Requirements

Installed and configured:

* libvirt and KVM
* virt-install
* ONE tools (oneimage)
* OCCI tools (occi-storage)
* disabled SELinux??

# Quick Start

Build and upload new/updated Debian 6:

    cd debian6
    make
