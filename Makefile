SHELL                := /bin/sh
GUEST_SHELL          ?= /bin/ksh93

SUITE                ?= stable
VARIANT              ?= important
MIRROR               ?= http://deb.debian.org/debian
INCLUDEPKGS          ?= ksh,strace

HOST_ARCH            := $(shell uname -m)

ifeq ($(HOST_ARCH),aarch64)
TARGET_ARCH           := arm64
KERNEL_ARCH           := arm64
DEBIAN_ARCH           := arm64
QEMU_ARCH             := aarch64
QEMU_PACKAGE          := qemu-system-arm
QEMU_MACHINE          := virt
CONSOLE               := ttyAMA0
KERNEL_FILE           := arch/arm64/boot/Image
KERNEL_ARGS           := console=$(CONSOLE) earlycon rdinit=/init
else ifeq ($(HOST_ARCH),x86_64)
TARGET_ARCH           := amd64
KERNEL_ARCH           := x86
DEBIAN_ARCH           := amd64
QEMU_ARCH             := x86_64
QEMU_PACKAGE          := qemu-system-x86
QEMU_MACHINE          := q35
CONSOLE               := ttyS0
KERNEL_FILE           := arch/x86/boot/bzImage
KERNEL_ARGS           := console=$(CONSOLE) earlyprintk=serial rdinit=/init
else
$(error Unsupported host architecture: $(HOST_ARCH))
endif

QEMU                 ?= qemu-system-$(QEMU_ARCH)
QEMU_CPU             ?= max
QEMU_CPUS            ?= 1
QEMU_MEMORY          ?= 2G
QEMU_EXTRA_ARGS      ?=
QEMU_CONSOLE_ARGS    ?= -nographic
GDB_PORT             ?= 1234
GDB                  ?= gdb
KERNEL_EXTRA_ARGS    ?=
DEBUG_KERNEL_ARGS    ?= nokaslr panic=-1 oops=panic

KERNELSRC            ?= $(CURDIR)/mainline
KERNELIMG            ?= $(KERNELSRC)/$(KERNEL_FILE)
VMLINUX              ?= $(KERNELSRC)/vmlinux
KERNEL_RELEASE       ?= $(KERNELSRC)/include/config/kernel.release
MODULES_ORDER        ?= $(KERNELSRC)/modules.order
KERNEL_BUILD_INPUTS  := $(wildcard $(KERNELIMG) $(KERNEL_RELEASE) $(MODULES_ORDER))
MAKEFILE_SELF        := $(lastword $(MAKEFILE_LIST))

OUTPUT_ROOT          ?= $(CURDIR)/out
OUTPUT_DIR           ?= $(OUTPUT_ROOT)/$(TARGET_ARCH)
MODULES_DIR          ?= $(OUTPUT_DIR)/modules
ROOTFS               ?= $(OUTPUT_DIR)/rootfs.tar
INITRAMFS            ?= $(OUTPUT_DIR)/initramfs.cpio
SERIAL_LOG           ?= $(OUTPUT_DIR)/console.log
ROOTFS_OVERLAY       ?=

ifneq ($(strip $(ROOTFS_OVERLAY)),)
ROOTFS_OVERLAY_ABS   := $(abspath $(ROOTFS_OVERLAY))
ROOTFS_OVERLAY_ARG   := --customize-hook="sync-in '$(ROOTFS_OVERLAY_ABS)' /"
endif

.DEFAULT_GOAL := help
.DELETE_ON_ERROR:

HOST_DEPS := \
	libarchive-tools \
	mmdebstrap \
	$(QEMU_PACKAGE) \
	kmod \
	gdb

.PHONY: \
		help print-config check check-image check-boot check-apt \
		check-gdb image copy-modules boot boot-log debug gdb \
		deps clean \
		distclean rebuild

define INIT
#!/bin/sh
set -eu

mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t devtmpfs dev /dev
mount -t debugfs none /sys/kernel/debug

hostname kernel-utils
export TERM=xterm-256color

exec agetty --autologin root --noclear $(CONSOLE) linux
endef
export INIT

help:
	@echo "Package and boot an already-built native Linux kernel with a Debian initramfs."
	@echo ""
	@echo "Usage: make [target] [VARIABLE=value ...]"
	@echo ""
	@echo "Primary targets:"
	@echo "  make image          Create the initramfs if it's missing"
	@echo "  make boot           Boot the kernel with QEMU"
	@echo "  make boot-log       Boot and write the serial console to a file"
	@echo "  make debug          Boot paused and wait for GDB on port $(GDB_PORT)"
	@echo "  make gdb            Connect GDB to the debug target"
	@echo "  make rebuild        Recreate the initramfs from scratch"
	@echo ""
	@echo "Additional targets:"
	@echo "  make deps           Install packaging, QEMU, and debug tools"
	@echo "  make check          Validate tools and configured paths"
	@echo "  make print-config   Show the resolved configuration"
	@echo "  make clean          Remove artifacts for the current architecture"
	@echo "  make distclean      Remove artifacts for all architectures"
	@echo ""
	@echo "Configuration variables:"
	@echo "  KERNELSRC           Kernel source directory"
	@echo "  SUITE               Debian suite (default: $(SUITE))"
	@echo "  VARIANT             mmdebstrap variant (default: $(VARIANT))"
	@echo "  MIRROR              Debian mirror"
	@echo "  INCLUDEPKGS         Additional guest packages"
	@echo "  OUTPUT_ROOT         Root output directory"
	@echo "  QEMU_CPU            QEMU CPU model and features (default: $(QEMU_CPU))"
	@echo "  QEMU_CPUS           Number of guest CPUs (default: $(QEMU_CPUS))"
	@echo "  QEMU_MEMORY         Guest memory size (default: $(QEMU_MEMORY))"
	@echo "  QEMU_EXTRA_ARGS     Additional QEMU command-line arguments"
	@echo "  KERNEL_EXTRA_ARGS   Additional kernel command-line arguments"
	@echo "  ROOTFS_OVERLAY      Directory to merge into the initramfs root"
	@echo "  SERIAL_LOG          Serial log path"
	@echo "  DEBUG_KERNEL_ARGS   Extra kernel arguments used by make debug"
	@echo "  GDB_PORT            Debug target's GDB port (default: $(GDB_PORT))"
	@echo "  GDB                 GDB executable (default: $(GDB))"
	@echo "  VMLINUX             Uncompressed kernel image with debug symbols"
	@echo ""
	@echo "Examples:"
	@echo '  make image KERNELSRC=/path/to/linux SUITE=testing'
	@echo '  make boot QEMU_CPU=max QEMU_CPUS=4 QEMU_MEMORY=4G'
	@echo '  make boot KERNEL_EXTRA_ARGS="ignore_loglevel initcall_debug"'
	@echo '  make boot QEMU_CPU=host QEMU_EXTRA_ARGS="-enable-kvm"'
	@echo '  make rebuild ROOTFS_OVERLAY=./overlay'
	@echo '  make boot-log SERIAL_LOG=/tmp/kernel-console.log'
	@echo '  make debug GDB_PORT=2345 QEMU_MEMORY=4G'
	@echo '  make gdb GDB_PORT=2345'

print-config:
	@echo "Host architecture:    $(HOST_ARCH)"
	@echo "Target architecture:  $(TARGET_ARCH)"
	@echo "Kernel architecture:  $(KERNEL_ARCH)"
	@echo "Debian architecture:  $(DEBIAN_ARCH)"
	@echo "Kernel source:        $(KERNELSRC)"
	@echo "Kernel image:         $(KERNELIMG)"
	@echo "Kernel symbols:       $(VMLINUX)"
	@echo "Output root:          $(OUTPUT_ROOT)"
	@echo "Output directory:     $(OUTPUT_DIR)"
	@echo "Initramfs:            $(INITRAMFS)"
	@echo "QEMU:                 $(QEMU)"
	@echo "QEMU machine:         $(QEMU_MACHINE)"
	@echo "QEMU CPU:             $(QEMU_CPU)"
	@echo "QEMU CPUs:            $(QEMU_CPUS)"
	@echo "QEMU memory:          $(QEMU_MEMORY)"
	@echo "QEMU extra arguments: $(QEMU_EXTRA_ARGS)"
	@echo "Kernel extra args:    $(KERNEL_EXTRA_ARGS)"
	@echo "Rootfs overlay:       $(ROOTFS_OVERLAY)"
	@echo "Serial log:           $(SERIAL_LOG)"
	@echo "Debug kernel args:    $(DEBUG_KERNEL_ARGS)"
	@echo "GDB port:             $(GDB_PORT)"
	@echo "Console:              $(CONSOLE)"

check: check-image check-boot

check-image:
	@command -v mmdebstrap >/dev/null || { \
		echo "error: mmdebstrap is not installed; run 'make deps'"; \
		exit 1; \
	}
	@command -v bsdtar >/dev/null || { \
		echo "error: bsdtar is not installed; run 'make deps'"; \
		exit 1; \
	}
	@test -d "$(KERNELSRC)" || { \
		echo "error: kernel source directory not found: $(KERNELSRC)"; \
		echo "Set it with: make image KERNELSRC=/path/to/linux"; \
		exit 1; \
	}
	@test -f "$(KERNELSRC)/Makefile" || { \
		echo "error: no kernel Makefile found in $(KERNELSRC)"; \
		exit 1; \
	}
	@test -f "$(KERNELIMG)" || { \
		echo "error: built kernel image not found: $(KERNELIMG)"; \
		echo "Build the kernel separately, then run 'make image'."; \
		exit 1; \
	}
	@test -f "$(KERNEL_RELEASE)" || { \
		echo "error: built kernel release metadata not found: $(KERNEL_RELEASE)"; \
		echo "Build the kernel separately, then run 'make image'."; \
		exit 1; \
	}
	@test -f "$(MODULES_ORDER)" || { \
		echo "error: built kernel modules not found: $(MODULES_ORDER)"; \
		echo "Build the kernel and modules separately, then run 'make image'."; \
		exit 1; \
	}
	@if test -n "$(ROOTFS_OVERLAY)" && test ! -d "$(ROOTFS_OVERLAY)"; then \
		echo "error: rootfs overlay directory not found: $(ROOTFS_OVERLAY)"; \
		exit 1; \
	fi

check-boot:
	@command -v "$(QEMU)" >/dev/null || { \
		echo "error: $(QEMU) is not installed; run 'make deps'"; \
		exit 1; \
	}
	@test -f "$(KERNELIMG)" || { \
		echo "error: built kernel image not found: $(KERNELIMG)"; \
		echo "Build the kernel separately, then run 'make boot'."; \
		exit 1; \
	}

check-gdb:
	@command -v "$(GDB)" >/dev/null || { \
		echo "error: $(GDB) is not installed; run 'make deps'"; \
		exit 1; \
	}
	@test -f "$(VMLINUX)" || { \
		echo "error: kernel symbols not found: $(VMLINUX)"; \
		exit 1; \
	}

$(OUTPUT_DIR):
	mkdir -p "$@"

copy-modules: | $(OUTPUT_DIR)
	rm -rf "$(MODULES_DIR)"
	$(MAKE) -C "$(KERNELSRC)" \
		ARCH="$(KERNEL_ARCH)" \
		INSTALL_MOD_PATH="$(MODULES_DIR)" \
		modules_install

image: $(INITRAMFS)

rebuild: clean
	$(MAKE) image

$(INITRAMFS): $(KERNEL_BUILD_INPUTS) $(MAKEFILE_SELF) | check-image $(OUTPUT_DIR)
	rm -f "$(ROOTFS)"
	$(MAKE) copy-modules

	mmdebstrap --architectures="$(DEBIAN_ARCH)" \
		--mode=unshare --variant="$(VARIANT)" \
		--include="$(INCLUDEPKGS)" \
		--aptopt='APT::Sandbox::User "root"' \
		--customize-hook='printf "%s\n" "$$INIT" > "$$1/init"' \
		--customize-hook='chmod 0755 "$$1/init"' \
		--customize-hook='chroot "$$1" chsh -s $(GUEST_SHELL) root' \
		--customize-hook="copy-in '$(MODULES_DIR)/lib/modules' /lib" \
		$(ROOTFS_OVERLAY_ARG) "$(SUITE)" "$(ROOTFS)" "$(MIRROR)"

	bsdtar --format newc -cf "$@" @"$(ROOTFS)"
	rm -rf "$(ROOTFS)" "$(MODULES_DIR)"

boot: check-boot $(INITRAMFS)
	$(QEMU) $(QEMU_EXTRA_ARGS) \
		-M "$(QEMU_MACHINE)" \
		-cpu "$(QEMU_CPU)" -smp "$(QEMU_CPUS)" \
		$(QEMU_CONSOLE_ARGS) -m "$(QEMU_MEMORY)" \
		-kernel "$(KERNELIMG)" \
		-initrd "$(INITRAMFS)" \
		-append "$(KERNEL_ARGS) $(KERNEL_EXTRA_ARGS)"

boot-log:
	mkdir -p "$(OUTPUT_DIR)"
	rm -f "$(SERIAL_LOG)"
	@echo "Serial console log: $(SERIAL_LOG)"
	$(MAKE) boot \
		QEMU_CONSOLE_ARGS="-display none -serial file:$(SERIAL_LOG) -monitor none"

debug:
	$(MAKE) boot \
		QEMU_EXTRA_ARGS="$(QEMU_EXTRA_ARGS) -S -gdb tcp:127.0.0.1:$(GDB_PORT)" \
		KERNEL_ARGS="$(KERNEL_ARGS) $(DEBUG_KERNEL_ARGS)"

gdb: check-gdb
	$(GDB) "$(VMLINUX)" \
		-ex "target remote 127.0.0.1:$(GDB_PORT)"

check-apt:
	@command -v apt-get >/dev/null || { \
		echo "error: dependency installation supports Debian-based systems only"; \
		exit 1; \
	}

deps: check-apt
	sudo apt-get install $(HOST_DEPS)

clean:
	rm -rf "$(OUTPUT_DIR)"

distclean:
	rm -rf "$(OUTPUT_ROOT)"
