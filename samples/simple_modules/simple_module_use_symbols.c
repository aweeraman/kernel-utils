#include <linux/module.h>
#include "simple_module.h"

MODULE_LICENSE("GPL");

int simple_module_use_init(void)
{
  printk(KERN_ALERT "Inside %s function\n", __FUNCTION__);
  simple_function_1();
  return 0;
}

void simple_module_use_exit(void)
{
  printk(KERN_ALERT "Inside %s function\n", __FUNCTION__);
}

module_init(simple_module_use_init);
module_exit(simple_module_use_exit);
