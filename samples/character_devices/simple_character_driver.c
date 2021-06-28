#include <linux/module.h>
#include <linux/fs.h> // Character driver support

MODULE_LICENSE("GPL");

/* For the operations to implement in the file_operations structure,
 * refer /lib/modules/4.14.8-1-ARCH/build/include/linux/fs.h */
ssize_t read_op(struct file *dfile, char __user *buffer, size_t length, loff_t *offset)
{
  printk(KERN_ALERT "Reading from device\n");
  return 0;
}

ssize_t write_op(struct file *dfile, const char __user *buffer, size_t size, loff_t *offset)
{
  printk(KERN_ALERT "Writing to device\n");
  return size;
}

int open_op(struct inode *dinode, struct file *dfile)
{
  printk(KERN_ALERT "Opening device\n");
  return 0;
}

int release_op(struct inode *dinode, struct file *dfile)
{
  printk(KERN_ALERT "Closing device\n");
  return 0;
}

struct file_operations driver_ops = {
  .owner   = THIS_MODULE,
  .open    = open_op,
  .write   = write_op,
  .read    = read_op,
  .release = release_op
};

int simple_module_init(void)
{
  printk(KERN_ALERT "Inside %s function\n", __FUNCTION__);

  /* Register a character device with the specified major number.
   * Check /proc/devices for already registered devices and use
   * a free one. You can create the device using
   * mknod -m 666 /dev/simple_driver c 200 0
   * To dynamically allocate a device number, use alloc_chrdev_region */
  register_chrdev(200                       /* Major number */,
		  "Simple Character Driver" /* Name of the driver */,
		  &driver_ops               /* File operations structure */);

  return 0;
}

void simple_module_exit(void)
{
  printk(KERN_ALERT "Inside %s function\n", __FUNCTION__);
  unregister_chrdev(200, "Simple Character Driver");
}

module_init(simple_module_init);
module_exit(simple_module_exit);
