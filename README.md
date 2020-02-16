# Kernel Development Utilities

This is a set of scripts and utilities to ease kernel development and testing in qemu.

## Create an initrd image
```
$ ./create-initrd.sh
```

# Create a debootstrapped file system
```
$ ./create-rootfs.sh
```

# Download and compile the kernel
```
$ mkdir src
$ cd src
$ git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
$ cd linux
$ make defconfig
$ make -j$(nproc)
$ cd ../../
```

# Launch the new kernel in qemu
```
$ ./boot.sh linux
```
