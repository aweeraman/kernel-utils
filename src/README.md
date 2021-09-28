# Kernel source directory

Place the kernel sources in a named directory here which will be used by the
boot.sh script to build and deploy into the VM.

Here are some standard repos:

Mainline:
```
$ git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git mainline
```

Stable:
```
$ git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git stable
```

Linux-next:
```
$ git clone https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git next
```

Staging:
```
$ git clone https://git.kernel.org/pub/scm/linux/kernel/git/gregkh/staging.git
```
