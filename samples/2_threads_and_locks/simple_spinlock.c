#include <linux/module.h>
#include <linux/kthread.h>
#include <linux/delay.h>
#include <linux/sched/signal.h>
#include <linux/spinlock.h>

MODULE_LICENSE("GPL");

// Initialize spinlock
static DEFINE_SPINLOCK(slock);

static struct task_struct *kthread1_struct, *kthread2_struct;

static int thread1_fn(void *unused) 
{
  allow_signal(SIGKILL);

  while(!kthread_should_stop()) {
    printk(KERN_INFO "Simple thread1 is running");
    ssleep(5);

    spin_lock(&slock);
    printk(KERN_INFO "Inside thread1 critical section");

    // Unlike in user space, signals should be manually
    // checked for, and actioned upon
    if (signal_pending(kthread1_struct)) {
      // Remember to unlock before returning out of a critical section
      spin_unlock(&slock);

      printk(KERN_INFO "Killing simple thread1 - SIGKILL received");
      break;
    }

    spin_unlock(&slock);
  }

  printk(KERN_INFO "Simple thread1 is stopping");

  do_exit(0);
  return 0;
}

static int thread2_fn(void *unused) 
{
  allow_signal(SIGKILL);

  while(!kthread_should_stop()) {
    printk(KERN_INFO "Simple thread2 is running");
    ssleep(5);

    spin_lock(&slock);
    printk(KERN_INFO "Inside thread2 critical section");

    // Unlike in user space, signals should be manually
    // checked for, and actioned upon
    if (signal_pending(kthread2_struct)) {
      // Remember to unlock before returning out of a critical section
      spin_unlock(&slock);

      printk(KERN_INFO "Killing simple thread2 - SIGKILL received");
      break;
    }

    spin_unlock(&slock);
  }

  printk(KERN_INFO "Simple thread2 is stopping");

  do_exit(0);
  return 0;
}

static int __init simple_module_init(void)
{
  printk(KERN_INFO "Creating thread");

  kthread1_struct = kthread_run(thread1_fn, NULL, "simplethread1");
  kthread2_struct = kthread_run(thread2_fn, NULL, "simplethread2");

  if (kthread1_struct && kthread2_struct) {
    printk(KERN_INFO "Created threads SUCCESSFULLY\n");
  } else {
    printk(KERN_ERR "Creating threads FAILED\n");
  }

  return 0;
}

static void __exit simple_module_exit(void)
{
  printk(KERN_ALERT "Inside %s function\n", __FUNCTION__);

  if (kthread1_struct) {
    kthread_stop(kthread1_struct);
    printk(KERN_INFO "Simple thread1 stopped");
  }

  if (kthread2_struct) {
    kthread_stop(kthread2_struct);
    printk(KERN_INFO "Simple thread2 stopped");
  }
}

module_init(simple_module_init);
module_exit(simple_module_exit);
