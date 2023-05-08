#!/bin/sh
#
# SPDX-FileCopyrightText: 2020 Anuradha Weeraman <anuradha@weeraman.com>
# SPDX-License-Identifier: GPL-3.0-or-later

set -e

kernel=$1

basedir=$(dirname $(readlink -f $0))
. ${basedir}/config/env.sh

qemu=qemu-system-${qemu_arch}

check_availability_of() {
	prog=$1
	if ! command -v ${prog} 2>&1 > /dev/null; then
		echo "$prog not found in path. Please install and try again."
		exit 1
	fi
}

check_availability_of time
check_availability_of make
check_availability_of lz4c
check_availability_of sudo
check_availability_of $qemu

if [ ! -d ${srcdir} ]; then
  echo "Please copy kernel sources into ${srcdir}."
  exit 1
fi

count=$(ls -1 ${srcdir} | wc -l)
if [ "${count}" -eq 0 ]; then
  echo "Please copy kernel sources into ${srcdir}."
  exit 1
fi

if [ -z "${kernel}" ]; then
  echo "Please specify the kernel that you would like to use, such as:"
  for dir in $(find ${srcdir} -mindepth 1 -maxdepth 1 \
	                      -type d -exec basename {} \; | grep -v ${srcdir}); do
    [ -e ${srcdir}/${dir}/MAINTAINERS ] && echo $dir
  done
  exit 1
fi

if [ ! -e "${srcdir}/${kernel}" ]; then
  echo "Please copy kernel sources into src/. For example, src/stable"
  exit 1
fi

bzImage=${srcdir}/${kernel}/arch/${kernel_arch}/boot/bzImage
vmlinux=${srcdir}/${kernel}/vmlinux

if [ ! -e "${bzImage}" ]; then
  echo -n "No built kernel found, build one? (y / default: n) "
  read input
  if [ "${input}" = "y" ]; then
    echo -n "Kernel configuration (default: config/default.cfg): "
    read kernelcfg
    if [ -z "${kernelcfg}" ]; then
      kernelcfg="${basedir}/config/default.cfg"
    fi
    echo "Building with ${kernelcfg}..."
    (
      cp ${kernelcfg} ${srcdir}/${kernel}/.config
      cd ${srcdir}/${kernel}
      time make ${compiler_flags} -j${procs} bzImage modules
    )
  else
    echo "Build the kernel manually, and try again."
    exit 0
  fi
fi

if [ "${boot_into_initrd_shell}" = "n" ]; then

  echo "Mounting ${rootfs} on loopback... "
  if [ ! -e ${rootfs} ]; then
    sudo mkdir ${rootfs}
  fi
  sudo umount ${rootfs} || true
  sudo mount -o loop ${basedir}/rootfs.img ${rootfs}

  if [ -e "${vmlinux}" ]; then
    sudo cp ${vmlinux} ${rootfs}
  fi

  if [ ! -z "${rootfs}" ]; then
    echo "Removing existing kernel modules..."
    sudo rm -rf ${rootfs}/lib/modules/*
  fi

  if [ "${copy_modules_to_rootfs}" = "y" ]; then
      (
        cd ${srcdir}/${kernel}
        echo "Copying kernel modules to rootfs..."
        sudo make INSTALL_MOD_PATH=${rootfs} modules_install
      )
  fi

  if [ "${copy_samples_to_rootfs}" = "y" ]; then
      (
        cd ${samplesdir}
        KERNEL_PATH=${srcdir}/${kernel} PROCS=${procs} make ${compiler_flags} all

        echo "Copying sample kernel modules to rootfs..."
        sudo KERNEL_PATH=${srcdir}/${kernel} INSTALL_MOD_PATH=${rootfs} make install
      )
  fi

  sudo umount ${rootfs}
  sudo rmdir ${rootfs}
fi


echo "Booting kernel: ${bzImage}"

debug_args=""
if [ "${wait_for_gdb_at_boot}" = "y" ]; then
  debug_args=${qemu_debug_args}
fi

qemu_args=""
append_args=""
netdev_args="user,id=network0 -device e1000,netdev=network0"

if [ "${boot_into_initrd_shell}" = "y" ]; then
  qemu_args="-initrd ${basedir}/initramfs.cpio.gz"
  append_args="init=/init"
else
  qemu_args="-hda ${basedir}/rootfs.img"
  append_args="root=/dev/sda init=/lib/systemd/systemd"
fi

${qemu} -m ${memory} -kernel ${bzImage} ${qemu_args} -nographic \
	-append "${append_args} rw console=ttyS0 earlyprintk=vga nokaslr selinux=0 audit=0 debug" \
	-enable-kvm ${debug_args} \
	-netdev ${netdev_args}
