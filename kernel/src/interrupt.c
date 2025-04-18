//! https://wiki.osdev.org/8259_PIC#Programming_the_PIC_chips
#include "../include/interrupt.h"
#include "../include/asm.h"
#include "../include/console.h"

// ICW - Initialization command words
// OCW - Operating -
//

#define PIC_EOI 0x20
#define PIC1 0x20 /* IO base address for master PIC */
#define PIC2 0xA0 /* IO base address for slave PIC */
#define PIC1_COMMAND PIC1
#define PIC1_DATA (PIC1 + 1)
#define PIC2_COMMAND PIC2
#define PIC2_DATA (PIC2 + 1)

#define ICW1_ICW4 0x01      /* Indicates that ICW4 will be present */
#define ICW1_SINGLE 0x02    /* Single (cascade) mode */
#define ICW1_INTERVAL4 0x04 /* Call address interval 4 (8) */
#define ICW1_LEVEL 0x08     /* Level triggered (edge) mode */
#define ICW1_INIT 0x10      /* Initialization - required! */

#define ICW4_8086 0x01       /* 8086/88 (MCS-80/85) mode */
#define ICW4_AUTO 0x02       /* Auto (normal) EOI */
#define ICW4_BUF_SLAVE 0x08  /* Buffered mode/slave */
#define ICW4_BUF_MASTER 0x0C /* Buffered mode/master */
#define ICW4_SFNM 0x10       /* Special fully nested (not) */

struct idt_entry idt[256];

static inline void io_wait(void)
{
    outb(0x80, 0);
}

// Remap of the PIC to not overlap with CPU interrupts
void pic_init()
{
    outb(PIC1_COMMAND, ICW1_INIT | ICW1_ICW4); // starts the initialization sequence (in cascade mode)
    io_wait();
    outb(PIC2_COMMAND, ICW1_INIT | ICW1_ICW4);
    io_wait();
    outb(PIC1_DATA, 0x20); // ICW2: Master PIC vector offset
    io_wait();
    outb(PIC2_DATA, 0x70); // ICW2: Slave PIC vector offset
    io_wait();
    outb(PIC1_DATA, 4); // ICW3: tell Master PIC that there is a slave PIC at IRQ2 (0000 0100)
    io_wait();
    outb(PIC2_DATA, 2); // ICW3: tell Slave PIC its cascade identity (0000 0010)
    io_wait();

    outb(PIC1_DATA, ICW4_8086); // ICW4: have the PICs use 8086 mode (and not 8080 mode)
    io_wait();
    outb(PIC2_DATA, ICW4_8086);
    io_wait();

    // Unmask both PICs.
    outb(PIC1_DATA, 0);
    outb(PIC2_DATA, 0);
}

void pic_eoi(uint8_t irq)
{
    if (irq >= 8) outb(PIC2_COMMAND, PIC_EOI);
    outb(PIC1_COMMAND, PIC_EOI);
}

__attribute__((interrupt)) void
interrupt_handler(struct interrupt_frame *frame)
{
    kprint("Interrupt\n", 0x0F);
    //pic_eoi(1);

    //keyboard handling
    //uint16_t scan = inb(0x60);
    //debug_hex(scan);
}

__attribute__((interrupt)) void
timer_handler(struct interrupt_frame *frame)
{
    //kprint("timer\n", 0x0F);
    pic_eoi(0x0);
}

struct idtr_desc
{
    unsigned short size;
    unsigned int base;
} __attribute__((packed));

static inline void lidt(void *base, uint16_t size)
{
    struct idtr_desc IDTR = {size - 1, (uint32_t)base};
    //struct idtr_desc *IDTR_ptr = &IDTR;

    asm("lidt %0" : : "m"(IDTR));
}

void add_inter(int vector, void (*interrupt)())
{
    uint32_t addr = (uint32_t)interrupt;
    idt[vector].offset_low = addr & 0xFFFF;
    idt[vector].selector = 0x08;
    idt[vector].zero = 0;
    // idt[vector].type = 0x8E;
    idt[vector].type = 0x8E;
    idt[vector].offset_high = (addr >> 16) & 0xFFFF;
}

void idt_init()
{
    // chain here all the interrupts to idt using add_inter
    add_inter(0x0, interrupt_handler);
    add_inter(0x0D, interrupt_handler);
    add_inter(0x08, interrupt_handler);
    add_inter(0x03, interrupt_handler);
    add_inter(0x20, timer_handler);
    //keyboard 
    //add_inter(0x21, interrupt_handler);
    lidt(idt, sizeof(idt));
}
