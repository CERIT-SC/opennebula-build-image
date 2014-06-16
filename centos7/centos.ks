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
part /boot --fstype=ext4 --size=256 --label=boot
part pv.01 --size=1024 --grow
volgroup VolGroup pv.01
logvol / --fstype=ext4 --name=root --vgname=VolGroup --size=512 --grow --fsoptions="defaults,usrjquota=aquota.user,grpjquota=aquota.group,jqfmt=vfsv0"
bootloader --location=mbr --append="elevator=deadline console=tty0 console=ttyS0,115200"

# Install repositories
#repo --name=updates --baseurl=http://mirror.centos.org/centos/7/updates/x86_64/
#repo --name=extras  --baseurl=http://mirror.centos.org/centos/7/extras/x86_64/

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
install -Dp --mode=644 /RPM-GPG-KEY-CERIT-SC.cfg /mnt/sysimage/etc/pki/rpm-gpg/RPM-GPG-KEY-CERIT-SC
quotacheck -vcguma
chroot /mnt/sysimage restorecon -Fi aquota.user aquota.group
quotaon -a
%end

%post --erroronfail --log=/dev/console
set -e
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CERIT-SC

#TODO: insecure, remove in stable release
#rpm --import http://ftp.linux.cz/pub/linux/redhat/rhel/rc/7/Server/x86_64/os/RPM-GPG-KEY-redhat-beta
#rpm --import http://ftp.linux.cz/pub/linux/redhat/rhel/rc/7/Server/x86_64/os/RPM-GPG-KEY-redhat-release 

cat <<EOF >/etc/yum.repos.d/centos-base.repo
[centos-base]
name=CentOS base
baseurl=http://buildlogs.centos.org/centos/7/os/x86_64-20140614/
enabled=1
gpgcheck=0
EOF

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

#cat <<EOF >/etc/yum.repos.d/cloud-init.repo
#[cloud-init]
#name=CERIT-SC cloud-init RPM repository
#baseurl=http://yum.cerit-sc.cz/cloud-init/el/\$releasever
#enabled=1
#gpgcheck=1
#EOF

#yum -y install cloud-init
yum clean all

# lame VM contextualization
chmod +x /etc/rc.d/rc.local
cat <<EOF >>/etc/rc.d/rc.local

if ! [ -f /root/.ssh/authorized_keys ]; then
  mount -t iso9660 -L CONTEXT -o ro /mnt
  if [ -f /mnt/context.sh ]; then
    source /mnt/context.sh
    if [ "x\${SSH_KEY}" != 'x' ]; then
      mkdir -p /root/.ssh/
      echo "\${SSH_KEY}" >/root/.ssh/authorized_keys
      chmod 600 /root/.ssh/authorized_keys
      restorecon -R /root
    fi
  fi
  umount /mnt
fi
EOF

# network fixes
sed -i '/^HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-eth*
unlink /etc/hostname

# motd
cat <<EOF >/etc/motd

   ___ ___ ___  _ _____    ___  ___
  / __| __| _ \| |_   _|__/ __|/ __|'s experimental cloud image with
 | (__| _||   /| | | ||___\__ \ (__    CentOS 7
  \___|___|_|_\|_| |_|    |___/\___|   
 
EOF

# https://bugzilla.redhat.com/show_bug.cgi?id=756130
set +e
unlink /etc/udev/rules.d/70-persistent-net.rules
ln -s /dev/null /etc/udev/rules.d/70-persistent-net.rules
unlink /etc/udev/rules.d/70-persistent-cd.rules
ln -s /dev/null /etc/udev/rules.d/70-persistent-cd.rules
%end
