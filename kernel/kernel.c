#include "include/interrupt.h"
#include "include/asm.h"

extern unsigned char _bss_start, _bss_end;

unsigned char* bss_ptr = &_bss_start;

static inline __attribute__((always_inline)) void io_wait(void) {
    outb(0x80, 0);
}

__attribute__((section(".text.kmain"))) // To put first
void kmain() {
    // APIC, ACPI

    // FIXME:? kmain saves ebp on the stack and ret addr but it shouldnt
    while (bss_ptr < &_bss_end) {
        *bss_ptr++ = 0;
    }

    // div 0
    // interrupt error
    // keyboard
    //pic_init();
    idt_init();

    asm volatile ("sti");
    while (1) {
        __asm__ volatile ( "int $0x0" );

        io_wait();
        asm volatile ("hlt");
    }
}
