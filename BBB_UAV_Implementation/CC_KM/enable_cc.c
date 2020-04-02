#include <linux/module.h>       /* Needed by all modules */
#include <linux/kernel.h>       /* Needed for KERN_INFO */
#include <linux/init.h>         /* Needed for the macros */
static int __init enable_cc_arm(void)
{
    printk(KERN_INFO "mhasan::Enable ARM CC.\n");

    /* enable user-mode access to the performance counter*/
    asm ("MCR p15, 0, %0, C9, C14, 0\n\t" :: "r"(1));

    /* disable counter overflow interrupts (just in case)*/
    asm ("MCR p15, 0, %0, C9, C14, 2\n\t" :: "r"(0x8000000f));
    return 0;
}
static void __exit disable_cc_arm(void)
{
    printk(KERN_INFO "mhasan::Disable ARM CC.\n");

    /* Disable user-mode access to counters. */
    asm ("MCR p15, 0, %0, C9, C14, 0\n\t" :: "r"(0));
}

MODULE_AUTHOR("Monowar Hasan <mhasan11@illinois.edu>");
MODULE_LICENSE("Dual MIT/GPL");
MODULE_DESCRIPTION("Enables user-mode access to ARM cycle counters.");
//MODULE_VERSION("0:1.0-dev");


module_init(enable_cc_arm);
module_exit(disable_cc_arm);
