#!/bin/sh

set -e

kernel=$1

basedir=$(dirname $(readlink -f $0))
. ${basedir}/config/env.sh

qemu=qemu-system-${qemu_arch}

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

bzImage=${srcdir}/${kernel}/arch/${kernel_arch}/boot/bzImage

if test ! -e ${bzImage}; then
  echo "${bzImage} not found, building kernel... "
  (
    cd ${srcdir}/${kernel}
    time make -j${procs}
  )
fi

if test "${copy_modules_to_rootfs}x" = "yx"; then
  if [ ! -e ${rootfs} ]; then
    sudo mkdir ${rootfs}
  fi

  echo "Mounting ${rootfs} on loopback... "
  sudo mount -o loop ${basedir}/rootfs.img ${rootfs}

  if test ! -z "${kernel}"; then
    if test ! -d ${srcdir}/${kernel}; then
      echo "Copy the build the kernel sources in src/"
      exit 1
    fi
    (
      cd ${srcdir}/${kernel}
      sudo make -j${procs} modules
      sudo make INSTALL_MOD_PATH=${rootfs} modules_install
    )
  fi

  sync
  sudo umount ${rootfs}
  sudo rmdir ${rootfs}
fi

echo "Booting kernel: ${bzImage}"

${qemu} -m 512m -kernel ${bzImage} -nographic \
	-append "root=/dev/sda rw init=/lib/systemd/systemd console=ttyS0" \
	-hda rootfs.img \
	-enable-kvm
