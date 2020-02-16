#!/bin/sh

BASEDIR=$(dirname $(readlink -f $0))
PROCS=$(nproc)
CONFDIR=${BASEDIR}/config
INITRD=${BASEDIR}/initrd
ROOTFS=${BASEDIR}/rootfs
DEPSDIR=${BASEDIR}/deps
BUSYBOXDIR=${DEPSDIR}/busybox

echo initrd_fs
if [ ! -e ${INITRD} ]; then
  mkdir ${INITRD}
  cd ${INITRD}
  mkdir -p bin sbin etc proc sys usr/bin usr/sbin
  cd -
  cp ${CONFDIR}/init ${INITRD}/bin/init
fi

echo busybox
if [ ! -e ${BUSYBOXDIR} ]; then
  mkdir -p ${BUSYBOXDIR}
  cd ${DEPSDIR}
  git clone git@github.com:mirror/busybox.git
fi
cp ${CONFDIR}/busybox.config ${BUSYBOXDIR}/.config
cd ${BUSYBOXDIR}
make -j${PROCS}
make CONFIG_PREFIX=${INITRD} install
cd -

echo initrd
cd ${INITRD}
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ${BASEDIR}/initramfs.cpio.gz
cd -
