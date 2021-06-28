obj-y += simple_modules/
obj-y += threads_and_locks/
obj-y += character_devices/

all: 
	make -j$(PROCS) -C $(KERNEL_PATH) M=$(shell pwd) modules

install:
	make -C $(KERNEL_PATH) M=$(shell pwd) modules_install

clean:
	make -C $(KERNEL_PATH) M=$(shell pwd) clean

