# Kernel Development Utilities - Busybox integration

This is a set of scripts and utilities to ease busybox integration with linux kernel.

## Dependencies

Kernel build dependencies:

```
$ sudo apt-get install python3 e2fsprogs build-essential linux-source bc kmod cpio flex cpio libncurses5-dev
```

Other dependencies:

* qemu-system-x86 (optional)
* qemu-system-arm (optional)

## Creating an initrd image
```
$ bash mk-initrd <arch>
```

## Configuration (config/env.sh)
```
# Number of processor threads
procs=$(nproc)

# Directory locations
confdir=${basedir}/config
initrd=${basedir}/initrd
srcdir=${basedir}/src
rootfs=${basedir}/rootfs
depsdir=${basedir}/deps
samplesdir=${basedir}/samples
busyboxdir=${depsdir}/busybox

# Rootfs and VM configuration
hostname=wintermute
rootfs_size=512m
memory=512

# Option to compile and copy kernel modules to rootfs
copy_modules_to_rootfs=n
copy_samples_to_rootfs=n

# Build and runtime architectures
debootstrap_arch=amd64
qemu_arch=x86_64
kernel_arch=x86_64

# Boot into initramfs shell
boot_into_initrd_shell=n

# Set this to yes to stop the CPU at boot and wait for debugger
wait_for_gdb_at_boot=n
qemu_debug_args="-s -S"
```

## License

This project is distributed under the GPLv3 license.
