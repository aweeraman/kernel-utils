"""
  cd ${busyboxdir}

ARM
-------  
  make -j2 ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-
  make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- install

x86_64
-------  
  # make -j${procs} 2>&1 | tee -a ${basedir}/log
  # make CONFIG_PREFIX=${initrd} install 2>&1 | tee -a ${basedir}/log
"""
