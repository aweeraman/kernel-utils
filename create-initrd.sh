#!/bin/sh

set -e

basedir=$(dirname $(readlink -f $0))
procs=$(nproc)
confdir=${basedir}/config
initrd=${basedir}/initrd
depsdir=${basedir}/deps
busyboxdir=${depsdir}/busybox

echo -n "Creating initrd filesystem... "
if [ ! -e ${initrd} ]; then
  (
    mkdir ${initrd} && cd ${initrd}
    mkdir -p bin sbin etc proc sys usr/bin usr/sbin
  )
  cp ${confdir}/initrd_init ${initrd}/bin/init
fi
echo "ok"

echo "Building dependencies... "
if [ ! -e ${busyboxdir} ]; then
  mkdir -p ${busyboxdir}
  (
    cd ${depsdir}
    git clone git@github.com:mirror/busybox.git >> ${basedir}/log
  )
fi
cp ${confdir}/busybox.config ${busyboxdir}/.config
(
  cd ${busyboxdir}
  make -j${procs} >> ${basedir}/log 2>&1
  make CONFIG_PREFIX=${initrd} install >> ${basedir}/log 2>&1
)

echo -n "Building initrd... "
(
  cd ${initrd}
  $(find . -print0 | cpio --null -o --format=newc | \
	  gzip -9 > ${basedir}/initramfs.cpio.gz) 2>> ${basedir}/log
)
