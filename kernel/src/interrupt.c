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

static inline void io_wait(void) { outb(0x80, 0); }

// Remap of the PIC to not overlap with CPU interrupts
void pic_init() {
  outb(PIC1_COMMAND,
       ICW1_INIT |
           ICW1_ICW4); // starts the initialization sequence (in cascade mode)
  io_wait();
  outb(PIC2_COMMAND, ICW1_INIT | ICW1_ICW4);
  io_wait();
  outb(PIC1_DATA, 0x20); // ICW2: Master PIC vector offset
  io_wait();
  outb(PIC2_DATA, 0x70); // ICW2: Slave PIC vector offset
  io_wait();
  outb(
      PIC1_DATA,
      4); // ICW3: tell Master PIC that there is a slave PIC at IRQ2 (0000 0100)
  io_wait();
  outb(PIC2_DATA, 2); // ICW3: tell Slave PIC its cascade identity (0000 0010)
  io_wait();

  outb(PIC1_DATA,
       ICW4_8086); // ICW4: have the PICs use 8086 mode (and not 8080 mode)
  io_wait();
  outb(PIC2_DATA, ICW4_8086);
  io_wait();

  // Unmask both PICs.
  outb(PIC1_DATA, 0);
  outb(PIC2_DATA, 0);
}

void pic_eoi(uint8_t irq) {
  if (irq >= 8)
    outb(PIC2_COMMAND, PIC_EOI);
  outb(PIC1_COMMAND, PIC_EOI);
}

__attribute__((interrupt)) void DE(struct interrupt_frame *frame) {
  kprint("Divide Error Exception\n", 0x0F);
  while (1)
    asm("hlt");
  // pic_eoi(1);

  // keyboard handling
  // uint16_t scan = inb(0x60);
  // debug_hex(scan);
}

__attribute__((interrupt)) void DB(struct interrupt_frame *frame) {
  kprint("Debug Error Exception\n", 0x0F);
  while (1)
    asm("hlt");
}
__attribute__((interrupt)) void NMI(struct interrupt_frame *frame) {
  kprint("Non-Maskable Interrupt\n", 0x0F);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void BP(struct interrupt_frame *frame) {
  kprint("Breakpoint exception\n", 0x0F);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void OF(struct interrupt_frame *frame) {
  kprint("Overflow exception\n", 0x0F);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void BR(struct interrupt_frame *frame) {
  kprint("Bound Range Exceeded exception\n", 0x0F);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void UD(struct interrupt_frame *frame) {
  kprint("Invalid Opcode exception\n", 0x0F);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void NM(struct interrupt_frame *frame) {
  kprint("Device Not Available exception\n", 0x0F);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void DF(struct interrupt_frame *frame,
                                   uint32_t error_code) {
  kprint("Double Fault exception\n", 0x0F);
  debug_hex(error_code);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void CSO(struct interrupt_frame *frame) {
  kprint("Coprocessor Segment Overrun exception\n", 0x0F);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void TS(struct interrupt_frame *frame,
                                   uint32_t error_code) {
  kprint("Invalid TSS exception\n", 0x0F);
  debug_hex(error_code);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void NP(struct interrupt_frame *frame,
                                   uint32_t error_code) {
  kprint("Segment Not Present exception\n", 0x0F);
  debug_hex(error_code);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void SSF(struct interrupt_frame *frame,
                                    uint32_t error_code) {
  kprint("Stack-Segment Fault exception\n", 0x0F);
  debug_hex(error_code);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void GP(struct interrupt_frame *frame,
                                   uint32_t error_code) {
  kprint("General Protection Fault exception\n", 0x0F);
  debug_hex(error_code);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void PF(struct interrupt_frame *frame,
                                   uint32_t error_code) {
  kprint("Page Fault exception\n", 0x0F);
  debug_hex(error_code);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void MF(struct interrupt_frame *frame) {
  kprint("x87 Floating-Point exception\n", 0x0F);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void AC(struct interrupt_frame *frame,
                                   uint32_t error_code) {
  kprint("Alignment Check exception\n", 0x0F);
  debug_hex(error_code);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void MC(struct interrupt_frame *frame) {
  kprint("Machine Check exception\n", 0x0F);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void XM(struct interrupt_frame *frame) {
  kprint("SIMD Floating-Point exception\n", 0x0F);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void VE(struct interrupt_frame *frame) {
  kprint("Virtualization exception\n", 0x0F);
  while (1)
    asm("hlt");
}

__attribute__((interrupt)) void CP(struct interrupt_frame *frame,
                                   uint32_t error_code) {
  kprint("Control Protection exception\n", 0x0F);
  debug_hex(error_code);
  while (1)
    asm("hlt");
}
__attribute__((interrupt)) void timer_handler(struct interrupt_frame *frame) {
  // kprint("timer\n", 0x0F);
  pic_eoi(0x0);
}

struct idtr_desc {
  unsigned short size;
  unsigned int base;
} __attribute__((packed));

static inline void lidt(void *base, uint16_t size) {
  struct idtr_desc IDTR = {size - 1, (uint32_t)base};
  // struct idtr_desc *IDTR_ptr = &IDTR;

  asm("lidt %0" : : "m"(IDTR));
}

void add_inter(int vector, void (*interrupt)(), uint8_t type) {
  uint32_t addr = (uint32_t)interrupt;
  idt[vector].offset_low = addr & 0xFFFF;
  idt[vector].selector = 0x08;
  idt[vector].zero = 0;
  idt[vector].type = type;
  idt[vector].offset_high = (addr >> 16) & 0xFFFF;
}

void idt_init() {
  // chain here all the interrupts to idt using add_inter
  add_inter(0x00, DE, INTER);
  add_inter(0x01, DB, TRAP);
  add_inter(0x02, NMI, INTER);
  add_inter(
      0x03, BP,
      UTRAP); // Breakpoint UTRAP for user could also call it from user mode
  add_inter(0x04, OF, TRAP);  // Overflow
  add_inter(0x05, BR, INTER); // Bound Range Exceeded
  add_inter(0x06, UD, INTER); // Invalid Opcode
  add_inter(0x07, NM, INTER); // Device Not Available
  add_inter(0x08, DF, INTER); // Double Fault
  add_inter(
      0x09, CSO,
      INTER); // Coprocessor Segment Overrun (obsolete, but still reserved)
  add_inter(0x0A, TS, INTER);  // Invalid TSS
  add_inter(0x0B, NP, INTER);  // Segment Not Present
  add_inter(0x0C, SSF, INTER); // Stack-Segment Fault
  add_inter(0x0D, GP, INTER);  // General Protection Fault
  add_inter(0x0E, PF, INTER);  // Page Fault
  // 0x0F is reserved — skip it
  add_inter(0x10, MF, INTER); // x87 Floating-Point Exception
  add_inter(0x11, AC, INTER); // Alignment Check
  add_inter(0x12, MC, INTER); // Machine Check
  add_inter(0x13, XM, INTER); // SIMD Floating-Point Exception
  add_inter(0x14, VE, INTER); // Virtualization Exception
  // 0x15 to 0x1D are reserved — skip
  add_inter(0x1E, CP, INTER); // Control Protection Exception
  // 0x1F is reserved — skip
  add_inter(0x20, timer_handler, INTER);
  // keyboard
  // add_inter(0x21, interrupt_handler);
  lidt(idt, sizeof(idt));
}
