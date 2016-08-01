# Documentnation for RHEL7 Kickstart:
# https://access.redhat.com/site/documentation/en-US/Red_Hat_Enterprise_Linux/7-Beta/html/Installation_Guide/index.html
# http://docs.redhat.com/docs/en-US/Red_Hat_Enterprise_Linux/6/html/Installation_Guide/s1-kickstart2-options.html
text
install
lang en_US.UTF-8
keyboard us
timezone --utc --ntpservers=ntp.muni.cz,tik.cesnet.cz,tak.cesnet.cz Europe/Prague
firstboot --disable
network --device=eth0 --bootproto dhcp --onboot=yes
network --device=eth1 --bootproto dhcp --onboot=yes
skipx
cmdline
poweroff

# security
rootpw      --iscrypted *
authconfig	--enableshadow --passalgo=sha512
firewall    --disabled
selinux     --permissive

# Partitioning, bootloader
zerombr
clearpart --all --initlabel
#autopart 
part / --fstype=ext4 --size=1024 --grow --label=root --fsoptions="defaults,usrjquota=aquota.user,grpjquota=aquota.group,jqfmt=vfsv0"
bootloader --location=mbr --append="elevator=deadline console=tty0 console=ttyS0,115200"

# Install repositories
repo --name=updates --baseurl=http://mirror.centos.org/centos/7/updates/x86_64/
repo --name=extras  --baseurl=http://mirror.centos.org/centos/7/extras/x86_64/

%packages
@base
@core
@ Development Tools
emacs-nox
mc
dstat
xorg-x11-xauth
xterm
%end

%post --nochroot --erroronfail --log=/dev/console
set -e
install -Dp --mode=644 /cloud.cfg /mnt/sysimage/etc/cloud/cloud.cfg
install -Dp --mode=644 /RPM-GPG-KEY-EPEL-7.cfg /mnt/sysimage/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
quotacheck -vcguma
chroot /mnt/sysimage restorecon -Fi aquota.user aquota.group
quotaon -a
%end

%post --erroronfail --log=/dev/console
set -e
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

cat <<EOF >/etc/yum.repos.d/epel.repo
[epel]
name=Extra Packages for Enterprise Linux 7 - \$basearch
#baseurl=http://download.fedoraproject.org/pub/epel/7/\$basearch
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
EOF

yum -y install cloud-init cloud-utils-growpart
yum clean all

# network fixes
sed -i '/^HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-eth*
sed -i 's/DEFROUTE=yes/DEFROUTE=no/' /etc/sysconfig/network-scripts/ifcfg-eth[^0]*
echo 'DEVICE=eth0' >>/etc/sysconfig/network-scripts/ifcfg-eth0
unlink /etc/hostname

# https://bugzilla.redhat.com/show_bug.cgi?id=756130
set +e
unlink /etc/udev/rules.d/70-persistent-net.rules
ln -s /dev/null /etc/udev/rules.d/70-persistent-net.rules
unlink /etc/udev/rules.d/70-persistent-cd.rules
ln -s /dev/null /etc/udev/rules.d/70-persistent-cd.rules
%end
