procs=$(nproc)

confdir=${basedir}/config
initrd=${basedir}/initrd
srcdir=${basedir}/src
rootfs=${basedir}/rootfs
depsdir=${basedir}/deps
busyboxdir=${depsdir}/busybox

hostname=wintermute
rootfs_size=512m
copy_modules_to_rootfs=y

debootstrap_arch=amd64
qemu_arch=x86_64
kernel_arch=x86_64
