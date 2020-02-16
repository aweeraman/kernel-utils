#include <linux/module.h>

MODULE_LICENSE("GPL");

// Just as __init reclaims the memory of the init callback, any variables
// that have __initdata will be reclaimed after initialization
__initdata char *hello = "Hello World";

// __init can be specified here as this function is *only* invoked from
// the init method
__init void simple_function_1(void)
{
  printk(KERN_ALERT "Inside %s function\n", __FUNCTION__);
}

// This method is also invoked from the exit callback, so __init should not
// be specified here
void simple_function_2(void)
{
  printk(KERN_ALERT "Inside %s function\n", __FUNCTION__);
}

// __init causes the init method to be unloaded after execution
// to reclaim its memory. This can be used in cases where applicable
// to reduce the memory footprint.
__init int simple_module_init(void)
{
  printk(KERN_ALERT "Inside %s function\n", __FUNCTION__);
  printk(KERN_ALERT "%s\n", hello);
  simple_function_1();
  simple_function_2();
  return 0;
}

// Since there's no module_exit callback, this module is permanently loaded into
// kernel space.
module_init(simple_module_init);
