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
