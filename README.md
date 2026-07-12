# Linux Kernel QEMU Harness

A minimal self-contained Makefile for packaging an already-built Linux
kernel with a Debian initramfs and running it under QEMU.

Simply drop-in the Makefile to the working directory and use it as part of
your development workflow.

Building, configuring, updating, and selecting the kernel are deliberately out
of scope. Use your normal kernel development workflow, then point `KERNELSRC`
at its prepared build tree.

## Requirements

The supported host architectures are x86-64 and AArch64. Supported guest
architectures are amd64, arm64, and riscv64. The guest defaults to the host's
architecture and can be selected independently with `TARGET_ARCH`.

On Debian and Ubuntu, install the required initramfs, debugging, and runtime
tools for all supported guest architectures with:

```sh
make deps
```

## Quick start

First build a kernel using whatever source tree, configuration, compiler, and
build process you prefer. The build must produce the bootable kernel image. If
`modules.order` is present, the kernel modules are also installed in the
initramfs; otherwise, the initramfs is created without modules.

The default kernel source directory is `./mainline`. Thus, a directory arranged
like this needs no `KERNELSRC` argument:

```text
work/
|-- Makefile <-- This project
`-- mainline/
    |-- Makefile
    |-- vmlinux
    `-- arch/...
```

Run `make` without a target to see all targets, variables, and examples:

```sh
make
```

```sh
make image
make boot
```

`make boot` creates the initramfs automatically when it does not already exist,
so the short form is usually enough:

To package and boot a pre-built RISC-V kernel on either an amd64 or arm64 Debian
host, install the runtime dependencies and select the target when packaging or
booting:

```sh
make deps
make boot TARGET_ARCH=riscv64 KERNELSRC=/path/to/riscv64-build
```

`KERNELSRC` must point at the prepared kernel build tree containing
`include/config/kernel.release` and the architecture's boot image. If
`modules.order` is present, its already-built modules are installed too.
`vmlinux` is only required for the `gdb` target. This harness only packages
existing artifacts; it never compiles the kernel or modules.

For a foreign guest, `mmdebstrap` uses QEMU user-mode emulation and Linux
`binfmt_misc` while constructing the root filesystem. System-mode QEMU then
boots the completed kernel and initramfs. Cross-architecture guests use software
emulation; KVM acceleration and `QEMU_CPU=host` are only appropriate when the
host and guest architectures match.

## Using the Makefile from a kernel tree

The utility Makefile is self-contained and does not require the rest of this
repository at runtime. It can be copied or symlinked wherever it is convenient.

A Linux source tree already has a file named `Makefile`, so give this Makefile a
different name when placing it inside the tree:

Place or symlink it as `Makefile` in a parent directory whose kernel tree is
named `mainline`, then run `make` from that parent directory.

```sh
cd /path/to/work-dir
ln -s /path/to/kernel-utils/Makefile .
make boot
```

## Common workflows

Create an initramfs without starting QEMU:

```sh
make image
```

Force the initramfs to be recreated after changing its package list, Debian
suite, overlay, or kernel modules:

```sh
make rebuild
```

Choose a Debian suite and add guest packages:

```sh
make rebuild \
    SUITE=testing \
    INCLUDEPKGS=ksh,strace,iproute2
```

Merge local files into the initramfs. Paths inside the overlay correspond to
paths in the guest root filesystem:

```text
overlay/
|-- etc/
|   `-- motd
`-- root/
    `-- test.sh
```

```sh
make rebuild ROOTFS_OVERLAY=./overlay
```

Give QEMU more CPUs and memory:

```sh
make boot QEMU_CPUS=4 QEMU_MEMORY=4G
```

Use KVM acceleration on a compatible host:

```sh
make boot QEMU_CPU=host QEMU_EXTRA_ARGS=-enable-kvm
```

Pass additional arguments to the kernel:

```sh
make boot KERNEL_EXTRA_ARGS="ignore_loglevel initcall_debug"
```

Pass arbitrary devices or other options to QEMU:

```sh
make boot QEMU_EXTRA_ARGS="-nic user,model=virtio-net-pci"
```

This creates a QEMU user-mode network device, but the guest still needs the
corresponding kernel driver and a userspace network configuration or DHCP
client.

Capture the serial console in a file:

```sh
make boot-log
```

The default log is `out/<target-architecture>/console.log`. Override it with
`SERIAL_LOG=/path/to/log`.

## Kernel debugging

Build the kernel with debug information and retain the uncompressed `vmlinux`
file. Start QEMU paused with its GDB server listening on localhost:

```sh
make debug
```

In another terminal, connect GDB:

```sh
make gdb 
```

The default port is 1234. A different port can be selected consistently for
both commands:

```sh
make debug GDB_PORT=2345
make gdb GDB_PORT=2345
```

Useful GDB commands include:

```gdb
hbreak start_kernel
continue
layout src
layout regs
```

## Outputs and cleanup

Artifacts are stored under `out/<target-architecture>/` by default, independently
of the host architecture. Change the base directory with `OUTPUT_ROOT`:

```sh
make image OUTPUT_ROOT=/tmp/kernel-utils
```

Remove artifacts for the current architecture or for all architectures:

```sh
make clean
make distclean
```

Use `make print-config` to inspect all resolved paths and architecture-specific
settings, and `make check` to validate the configured tools and kernel files.

## Kernel configuration

The initramfs mounts procfs, sysfs, devtmpfs, and debugfs, then starts an
automatic root login on the architecture's serial console. The kernel must have
the required filesystem, console, and QEMU device support built in or available
through its installed modules.

At minimum, check the relevant options for your architecture and QEMU machine,
including initramfs support, devtmpfs, procfs, sysfs, a serial console, and the
drivers for any QEMU devices you add. Kernel configuration remains the
developer's responsibility because the correct choices depend on the kernel and
the experiment being run.

## License

This project is distributed under the GPLv3 license. See `COPYING`.
