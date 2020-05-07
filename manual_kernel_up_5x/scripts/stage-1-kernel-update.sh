#!/bin/bash

# install developer packages 

yum update -y
yum install -y ncurses-devel make gcc bc bison flex elfutils-libelf-devel openssl-devel grub2 rpm-build rsync wget hmaccalc zlib-devel binutils-devel epel-release patchutils bzip2 perl -y
yum update -y
yum install -y dkms

# Download kernel.org

cd /usr/src
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.4.39.tar.xz

# Unpacking kernel and compiling

tar xf linux-5.4.39.tar.xz
rm -f linux-5.4.39.tar.xz
cd linux-5.4.39
cp /boot/config-* /usr/src/linux-5.4.39/.config
make olddefconfig
make -j4 rpm-pkg
cd ..
rm -rfd linux-5.4.39

# Install New-kernel

rpm -iUv ~/rpmbuild/RPMS/x86_64/*.rpm
rm -frd ~/rpmbuild/*

# Update GRUB
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-set-default 0
echo "Grub update done."
# Reboot VM
shutdown -r now
