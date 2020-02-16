# Number of processor threads
procs=$(nproc)

# Directory locations
confdir=${basedir}/config
initrd=${basedir}/initrd
srcdir=${basedir}/src
rootfs=${basedir}/rootfs
depsdir=${basedir}/deps
busyboxdir=${depsdir}/busybox

hostname=wintermute
rootfs_size=512m
memory=512m

# Option to compile and copy kernel modules to rootfs
copy_modules_to_rootfs=y

debootstrap_arch=amd64
qemu_arch=x86_64
kernel_arch=x86_64

# Set this to yes to stop the CPU at boot and wait for debugger
wait_for_gdb_at_boot=n
qemu_debug_args="-s -S"
