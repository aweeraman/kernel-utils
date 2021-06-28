#include <linux/module.h>

MODULE_LICENSE("GPL");

void simple_function_1(void)
{
  printk(KERN_ALERT "Inside %s exported function\n", __FUNCTION__);
}

EXPORT_SYMBOL(simple_function_1);

int simple_module_export_init(void)
{
  printk(KERN_ALERT "Inside %s function\n", __FUNCTION__);
  return 0;
}

void simple_module_export_exit(void)
{
  printk(KERN_ALERT "Inside %s function\n", __FUNCTION__);
}

module_init(simple_module_export_init);
module_exit(simple_module_export_exit);
