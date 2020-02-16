#!/bin/sh

set -e

basedir=$(dirname $(readlink -f $0))
rootfs=${basedir}/rootfs
hostname=wintermute
rootfs_size=512m

echo -n "Creating rootfs... "
qemu-img create ${basedir}/rootfs.img ${rootfs_size} >> ${basedir}/log
mkfs.ext4 ${basedir}/rootfs.img >> ${basedir}/log

echo -n "Removing existing ${rootfs}, press ENTER to proceed... "
read input

if [ ! -e ${rootfs} ]; then
  sudo mkdir ${rootfs}
fi

echo -n "Mounting ${rootfs} on loopback... "
sudo mount -o loop ${basedir}/rootfs.img ${rootfs}
echo "ok"

echo -n "Bootstrapping filesystem... "
$(sudo debootstrap unstable ${rootfs} http://deb.debian.org/debian/ >> ${basedir}/log)
echo "ok"

echo -n "Setting hostname: ${hostname}... "
sudo bash -c "echo '${hostname}' > ${rootfs}/etc/hostname"
echo "ok"

echo "Set the root password... "
sudo chroot ${rootfs} /bin/bash -c "passwd root"

echo -n "Cleaning up... "
sudo umount ${rootfs}
sudo rmdir ${rootfs}
echo "ok"
