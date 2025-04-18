#include "include/asm.h"
#include "include/interrupt.h"
#include "include/console.h"

extern unsigned char _bss_start, _bss_end;

static inline __attribute__((always_inline)) void io_wait(void)
{
    outb(0x80, 0);
}

__attribute__((section(".text.kmain"))) // To put first
void kmain()
{
    // ⸮!?
    static unsigned char *bss_ptr = &_bss_start;
    while (bss_ptr < &_bss_end)
    {
        *bss_ptr++ = 0;
    }

    clear_console();

    uint8_t val = 5;
    bin(val);
    debug_hex(0x1);

    kprint("Test\nHello\naaa\n", 0x0F);
    // APIC, ACPI

    // FIXME:? kmain saves ebp on the stack and ret addr but it shouldnt

    pic_init();
    idt_init();
    //asm volatile ("int3");

    while (1)
    {
        asm volatile("sti");

        asm volatile("hlt");
    }
}
