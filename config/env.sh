# Tweak the compiler flags
# To use clang: compiler_flags="CC=clang HOSTCC=clang"
#compiler_flags="CC=clang HOSTCC=clang"

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

# Dependencies
busybox_tag=1_35_0

hostname=wintermute
rootfs_size=2048m
memory=512m

# Option to compile and copy kernel modules to rootfs
copy_modules_to_rootfs=y
copy_samples_to_rootfs=n

debootstrap_arch=amd64
qemu_arch=x86_64
kernel_arch=x86_64

# Boot into initramfs shell
boot_into_initrd_shell=n

# Set this to yes to stop the CPU at boot and wait for debugger
wait_for_gdb_at_boot=n
qemu_debug_args="-s -S"

# Packages to install on rootfs
packages_to_install="systemd-resolved bpftrace bpfcc-tools gdb"
