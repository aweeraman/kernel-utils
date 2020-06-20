#!/bin/bash

set -e

basedir=$(dirname $(readlink -f $0))
. ${basedir}/config/env.sh

if [ -e ${initrd} ]; then
  echo -n "Removing existing initrd, press ENTER to proceed... "
  read input
  rm -rf ${initrd}
fi

echo -n "Creating initrd filesystem... "
mkdir ${initrd} && cd ${initrd}
mkdir -p bin sbin etc proc sys usr/bin usr/sbin
cp ${confdir}/init ${initrd}/init
chmod a+x ${initrd}/init
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
  $(find . | cpio -oHnewc | gzip > ${basedir}/initramfs.cpio.gz) 2>> ${basedir}/log
)
