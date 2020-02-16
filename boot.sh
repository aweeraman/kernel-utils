#!/bin/sh

qemu-system-x86_64 -m 512m -kernel vmlinuz -nographic \
	-append "root=/dev/sda ro init=/lib/systemd/systemd console=ttyS0" \
	-hda rootfs.img
