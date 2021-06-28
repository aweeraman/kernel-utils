#include <linux/module.h>

MODULE_LICENSE("GPL");

__init int simple_module_init(void)
{
  printk(KERN_ALERT "Inside %s function\n", __FUNCTION__);
  return 0;
}

__exit void simple_module_exit(void)
{
  printk(KERN_ALERT "Inside %s function\n", __FUNCTION__);
}

module_init(simple_module_init);
module_exit(simple_module_exit);
