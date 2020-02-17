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
samplesdir=${basedir}/samples
busyboxdir=${depsdir}/busybox

# Rootfs and VM configuration
hostname=wintermute
rootfs_size=512m
memory=512

# Option to compile and copy kernel modules to rootfs
copy_modules_to_rootfs=y
copy_samples_to_rootfs=y

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

# Debugging

Set 'wait_for_gdb_at_boot=y' and at the gdb prompt, and run './boot.sh [kernel]'.
Qemu will wait for the debugger in order to proceed. From a different shell, start
'gdb ./vmlinux' and enter the following to continue booting and debugging. Also,
confirm that 'CONFIG_DEBUG_INFO=y' is set in the kernel config.

Here's a sample session:

```
(gdb) target remote :1234
Remote debugging using :1234

Program received signal SIGTRAP, Trace/breakpoint trap.
0x000000000000fff0 in exception_stacks ()
(gdb) hbreak start_kernel
Hardware assisted breakpoint 1 at 0xffffffff829e2cb5: file init/main.c, line 780.
(gdb) c
Continuing.

Breakpoint 1, start_kernel () at init/main.c:780
780	{
(gdb) n
784		set_task_stack_end_magic(&init_task);
(gdb) n
785		smp_setup_processor_id();
(gdb) n
788		cgroup_init_early();

```
