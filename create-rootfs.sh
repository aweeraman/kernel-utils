#!/bin/sh

BASEDIR=$(dirname $(readlink -f $0))
PROCS=$(nproc)
CONFDIR=${BASEDIR}/config
INITRD=${BASEDIR}/initrd
ROOTFS=${BASEDIR}/rootfs
DEPSDIR=${BASEDIR}/deps
BUSYBOXDIR=${DEPSDIR}/busybox

echo rootfs
qemu-img create ${BASEDIR}/rootfs.img 1024m
mkfs.ext4 ${BASEDIR}/rootfs.img
echo "removing existing ${ROOTFS}, press enter to proceed"
read input
sudo rmdir ${ROOTFS} || true
sudo mkdir ${ROOTFS}
echo "mounting ${ROOTFS} on loopback"
sudo mount -o loop ${BASEDIR}/rootfs.img ${ROOTFS}
echo "debootstrapping"
sudo debootstrap unstable ${ROOTFS} http://deb.debian.org/debian/
echo "setting root password"
sudo chroot ${ROOTFS} /bin/bash -c "passwd root"
echo "unmounting from loopback"
sudo umount ${ROOTFS}
sudo rmdir ${ROOTFS} || true
