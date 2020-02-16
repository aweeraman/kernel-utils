obj-y += 1_simple_modules/
obj-y += 2_threads_and_locks/
obj-y += 3_character_devices/

all: 
	make -j$(PROCS) -C $(KERNEL_PATH) M=$(shell pwd) modules

install:
	make -C $(KERNEL_PATH) M=$(shell pwd) modules_install

clean:
	make -C $(KERNEL_PATH) M=$(shell pwd) clean

