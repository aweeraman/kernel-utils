#include <linux/module.h>

MODULE_LICENSE("GPL");

int param = 1;

module_param(param /* parameter name */,
             int   /* parameter type */,
	     0644  /* permissions in sysfs accessible at
	              /sys/module/simple_module_param/parameters/param */);

int simple_module_init(void)
{
  printk(KERN_ALERT "Inside %s function with parameter %d\n", __FUNCTION__, param);
  return 0;
}

void simple_module_exit(void)
{
  printk(KERN_ALERT "Inside %s function\n", __FUNCTION__);
}

module_init(simple_module_init);
module_exit(simple_module_exit);
