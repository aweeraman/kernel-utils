# Kernel Development Utilities

This is a set of scripts and utilities to ease kernel development and testing in qemu.

## Dependencies

Kernel build dependencies:

```
$ sudo apt-get install e2fsprogs build-essential linux-source bc kmod cpio flex cpio libncurses5-dev
```

Other dependencies:

* debootstrap
* qemu-system-x86 (for now)
* ccache
* clang (optional)

## Step 1: Create an initrd image
```
$ ./mk-initrd
```

## Step 2: Create a debootstrapped file system

This step currently requires a Debian/Ubuntu (or derivative) distribution as it relies on
debootstrap.

```
$ ./mk-rootfs
```

## Step 3: Download and compile the kernel under src/
```
$ mkdir src
$ cd src
$ git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
$ cd linux
$ make defconfig
$ make -j$(nproc)
$ cd ../../
```

## Step 4: Launch the new kernel in qemu

To boot the kernel created in Step 3:

```
$ ./boot.sh linux
```

The argument to the script is the directory under src/ which holds the kernel. Multiple trees
of the kernel can exist under src/ and the directory name can be specified as an argument. Providing
no arguments will list the available kernels that can be booted.

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

## Debugging

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

## GDB Cheatsheet

```
gdb ./vmlinux, file ./vmlinux
gdb -tui, tui enable - enable text-user-interface mode
c-x s - switch to SingleKey mode
c-x 1 - same as "layout src"
c-x 2 - same as "layout regs"
c-x 0 - switch focus
c - continue
n - next
i - step in
disassemble _do_fork, disassemble 0xffffffff81064de0 - the location taken from System.map
hbreak start_kernel, break _do_fork - set breakpoint
set disassembly-flavor intel
```

## Troubleshooting

If you get the following error message when running the boot.sh script:

```
mount: [path]/rootfs: [path]/rootfs.img is already mounted.
```

Simply:

```
$ sudo umount rootfs
```

This is indicative of an error in a previous step, and will be tracked down and fixed.

# License

This project is distributed under the GPLv3 license.
