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

# Configuration (config/env.sh)
```
# Number of processor threads
procs=$(nproc)

# Directory locations
confdir=${basedir}/config
initrd=${basedir}/initrd
srcdir=${basedir}/src
rootfs=${basedir}/rootfs
depsdir=${basedir}/deps
busyboxdir=${depsdir}/busybox

# Rootfs and VM configuration
hostname=wintermute
rootfs_size=512m
memory=512

# Option to compile and copy kernel modules to rootfs
copy_modules_to_rootfs=y

# Build and runtime architectures
debootstrap_arch=amd64
qemu_arch=x86_64
kernel_arch=x86_64

# Set this to yes to stop the CPU at boot and wait for debugger
wait_for_gdb_at_boot=n
qemu_debug_args="-s -S"
```

# Debugging

Set 'wait_for_gdb_at_boot=y' and at the gdb prompt:

```
(gdb) target remote :1234
Remote debugging using :1234
warning: No executable has been specified and target does not support
determining executable automatically.  Try using the "file" command.

Program received signal SIGTRAP, Trace/breakpoint trap.
0x000000000000fff0 in ?? ()
(gdb) continue
Continuing.
```
