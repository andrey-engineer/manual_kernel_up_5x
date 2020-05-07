Сборка кастомизированного образа CentOS 7.8 с обновленным ядром 5.4.Х и установленным VirtualBox Guest Additions
За основу взят manual (https://github.com/dmitry-lyutenko/manual_kernel_update/blob/master/manual/manual.md)

Сборка нашего образа состоит из следующих шагов:
1) Установка базового дистрибутива CentOS 7.8
2) Установка требуемых пакетов для компиляции ядра и VBoxGuestAdditions
3) Сам процесс сборки и установки свежего ядра 
4) Копирование ssh ключа и установка VBoxGuestAdditions
5) Подготовка образа (чистка /tmp, /log и т.д.)

Приступим:

Переходим в директорию с проектом. Запускаем packer

[andrey@fedora Super-obraz]$ ./packer build centos.json

# Идет процесс скачивания дистрибутива и установка базового набора ПО.
# (stage-1-kernel-update.sh):

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

# 2 этап "Инсталляция VBoxGuestAdditions"
# (stage-2-vbox-guest-addon.sh)

#!/bin/bash

# clean all
yum update -y
yum clean all


# Install vagrant default key
mkdir -pm 700 /home/vagrant/.ssh
curl -sL https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -o /home/vagrant/.ssh/authorized_keys
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# Install VBOX guest additions
mount /home/vagrant/VBoxGuestAdditions.iso /media -o loop
KERN_DIR=/usr/src/kernels/`uname -r`/build
export KERN_DIR
cd /media
./VBoxLinuxAdditions.run
/sbin/rcvboxadd quicksetup all
usermod -aG vboxsf vagrant

# Reboot VM
shutdown -r now

# 3 Этап "Подготовка образа"
# (stage-3-clean.sh)

#!/bin/bash

modprobe -a vboxguest vboxsf vboxvideo

# Remove temporary files
rm -rf /tmp/*
rm  -f /var/log/wtmp /var/log/btmp
rm -rf /var/cache/* /usr/share/doc/*
rm -rf /var/cache/yum
rm -rf /vagrant/home/*.iso
rm  -f ~/.bash_history
history -c

rm -rf /run/log/journal/*

# Fill zeros all empty space
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
sync
grub2-set-default 0
echo "###   Hi from 3 stage" >> /boot/grub2/grub.cfg

# Сборка образа завершена:)
# Готовый образ залит на app.vagrantup.com
https://app.vagrantup.com/andrey-engineer/boxes/centos-7-8
