#!/bin/sh

set -e

kernel=$1

basedir=$(dirname $(readlink -f $0))
srcdir=${basedir}/src
arch=x86_64
qemu=qemu-system-x86_64

if test ! -d ${srcdir}; then
  echo "Please copy kernel sources into ${srcdir}."
  exit 1
fi

count=$(ls -1 ${srcdir} | wc -l)
if test ${count} -eq 0; then
  echo "Please copy kernel sources into ${srcdir}."
  exit 1
fi

if test -z "${kernel}"; then
  echo "Please specify the kernel that you would like to use"
  echo "Available options are: "
  ls -1 ${srcdir}
  exit 1
fi

if test ! -e "${srcdir}/${kernel}"; then
  echo "Please copy kernel sources into src/. For example, src/linux-next"
  exit 1
fi

bzImage=${srcdir}/${kernel}/arch/${arch}/boot/bzImage

if test ! -e ${bzImage}; then
  echo "${bzImage} not found, build the kernel first!"
  exit 1
fi

echo "Booting kernel: ${bzImage}"

${qemu} -m 512m -kernel ${bzImage} -nographic \
	-append "root=/dev/sda ro init=/lib/systemd/systemd console=ttyS0" \
	-hda rootfs.img
