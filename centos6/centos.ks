# Documentnation for RHEL6 Kickstart:
# http://docs.redhat.com/docs/en-US/Red_Hat_Enterprise_Linux/6/html/Installation_Guide/s1-kickstart2-options.html
text
install
lang en_US.UTF-8
keyboard us
timezone --utc CET
firstboot --disable
network --device=eth0 --bootproto dhcp --onboot=yes
network --device=eth1 --bootproto dhcp --onboot=yes
skipx
cmdline
reboot

# security
rootpw      --iscrypted *
authconfig	--enableshadow --passalgo=sha512
firewall    --enabled --ssh
selinux     --permissive

# Partitioning, bootloader
zerombr
clearpart --all --initlabel
#autopart 
part /boot --fstype=ext4 --size=256 --label=boot
part pv.01 --size=1024 --grow
volgroup VolGroup pv.01
logvol / --fstype=ext4	--name=root --vgname=VolGroup --size=512 --grow
bootloader --location=mbr --append="elevator=deadline console=tty0 console=ttyS0,115200"

# Repo: CentOS url --url http://mirror.centos.org/centos/6/os/x86_64/
repo --name=updates	--baseurl=http://mirror.centos.org/centos/6/updates/x86_64/
repo --name=extras	--baseurl=http://mirror.centos.org/centos/6/extras/x86_64/

%packages
@core
@ Development Tools
emacs-nox
mc
dstat
xorg-x11-xauth
xterm

%post --nochroot
tar --no-same-owner -xvf /cloud.tar -C /mnt/sysimage/etc/
cp /cloud-init-el6.rpm /mnt/sysimage/tmp

%post
# https://bugzilla.redhat.com/show_bug.cgi?id=510523
sed -i 's/rhgb//'	/etc/grub.conf
sed -i '/^HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-eth*

# https://bugzilla.redhat.com/show_bug.cgi?id=756130
unlink /etc/udev/rules.d/70-persistent-net.rules
ln -s /dev/null /etc/udev/rules.d/70-persistent-net.rules
unlink /etc/udev/rules.d/70-persistent-cd.rules
ln -s /dev/null /etc/udev/rules.d/70-persistent-cd.rules

set -e

# setup EPEL repository
EPEL_RELEASE_URL='http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm'
EPEL_RELEASE=$(mktemp)
EPEL_GPG_KEY=$(mktemp)
cat <<EOF >${EPEL_GPG_KEY}
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: SKS 1.1.3

mQINBEvSKUIBEADLGnUj24ZVKW7liFN/JA5CgtzlNnKs7sBg7fVbNWryiE3URbn1JXvrdwHt
kKyY96/ifZ1Ld3lE2gOF61bGZ2CWwJNee76Sp9Z+isP8RQXbG5jwj/4BM9HK7phktqFVJ8Vb
Y2jfTjcfxRvGM8YBwXF8hx0CDZURAjvf1xRSQJ7iAo58qcHnXtxOAvQmAbR9z6Q/h/D+Y/Ph
oIJp1OV4VNHCbCs9M7HUVBpgC53PDcTUQuwcgeY6pQgo9eT1eLNSZVrJ5Bctivl1UcD6P6CI
GkkeT2gNhqindRPngUXGXW7Qzoefe+fVQqJSm7Tq2q9oqVZ46J964waCRItRySpuW5dxZO34
WM6wsw2BP2MlACbH4l3luqtpXo3Bvfnk+HAFH3HcMuwdaulxv7zYKXCfNoSfgrpEfo2Ex4Im
/I3WdtwME/Gbnwdq3VJzgAxLVFhczDHwNkjmIdPAlNJ9/ixRjip4dgZtW8VcBCrNoL+LhDrI
fjvnLdRuvBHy9P3sCF7FZycaHlMWP6RiLtHnEMGcbZ8QpQHi2dReU1wyr9QgguGU+jqSXYar
1yEcsdRGasppNIZ8+Qawbm/a4doT10TEtPArhSoHlwbvqTDYjtfV92lC/2iwgO6gYgG9XrO4
V8dV39Ffm7oLFfvTbg5mv4Q/E6AWo/gkjmtxkculbyAvjFtYAQARAQABtCFFUEVMICg2KSA8
ZXBlbEBmZWRvcmFwcm9qZWN0Lm9yZz6JAjYEEwECACAFAkvSKUICGw8GCwkIBwMCBBUCCAME
FgIDAQIeAQIXgAAKCRA7Sd8qBgi4lR/GD/wLGPv9qO39eyb9NlrwfKdUEo1tHxKdrhNz+XYr
O4yVDTBZRPSuvL2yaoeSIhQOKhNPfEgT9mdsbsgcfmoHxmGVcn+lbheWsSvcgrXuz0gLt8TG
GKGGROAoLXpuUsb1HNtKEOwPQ4z1uQ2nOz5hLRyDOV0I2LwYV8BjGIjBKUMFEUxFTsL7XOZk
rAg/WbTH2PW3hrfSWtcRA7EYonI3B80d39ffws7SmyKbS5PmZjqOPuTvV2F0tMhKIhncBwoo
jWZPExftHpKhzKVh8fdDO/3P1y1Fk3Cin8UbCO9MWMFNR27fVzCANlEPljsHA+3Ez4F7uboF
p0OOEov4Yyi4BEbgqZnthTG4ub9nyiupIZ3ckPHr3nVcDUGcL6lQD/nkmNVIeLYPx1uHPOSl
WfuojAYgzRH6LL7Idg4FHHBA0to7FW8dQXFIOyNiJFAOT2j8P5+tVdq8wB0PDSH8yRpn4HdJ
9RYquau4OkjluxOWf0uRaS//SUcCZh+1/KBEOmcvBHYRZA5Jl/nakCgxGb2paQOzqqpOcHKv
lyLuzO5uybMXaipLExTGJXBlXrbbASfXa/yGYSAGiVrGz9CE6676dMlm8F+s3XXE13QZrXmj
loc6jwOljnfAkjTGXjiB7OULESed96MRXtfLk0W5Ab9pd7tKDR6QHI7rgHXfCopRnZ2VVQ==
=V/6I
-----END PGP PUBLIC KEY BLOCK-----
EOF

rpm --import ${EPEL_GPG_KEY} &&
	wget -O "${EPEL_RELEASE}" "${EPEL_RELEASE_URL}" &&
	rpm --checksig "${EPEL_RELEASE}" &&
	rpm -Uvh "${EPEL_RELEASE}" &&
	yum -y install /tmp/cloud-init-el6.rpm
