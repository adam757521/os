#include <stdint.h>
char stack[1024];
int thing = 1;
struct idt_entry {
  uint16_t offset_low;  // 0-15 bits of the offset
  uint16_t selector;    // code segement selector
  uint8_t zero;         // unuesd
  uint8_t type;         // gate,dpl,fields
  uint16_t offset_high; // bits 16-31 of the offset
};
struct idt_entry idt[256];
struct interrupt_frame { // save registers
  uint64_t rip;
  uint64_t cs;
  uint64_t rflags;
  uint64_t rsp;
  uint64_t ss;
};
__attribute__((interrupt)) void Divide_Error(struct interrupt_frame *frame) {
  print("an divide error occourred"); // not implemented yet
  while (1) {
    asm volatile("hlt");
  }
}
void add_inter(int vector, void (*interrupt)()) {
  uint32_t addr = (uint32_t)interrupt;
  idt[vector].offset_low = addr & 0xFFFF;
  idt[vector].selector = 0x08;
  idt[vector].zero = 0;
  idt[vector].type = 0x8E;
  idt[vector].offset_high = (addr >> 16) & 0xFFFF;
}
struct idtptr {
  uint16_t limit;
  uint32_t base;
};
void lidt(void *base, uint16_t size) {
  struct idtptr idtr;
  idtr.limit = size - 1;
  idtr.base = (uint32_t)base;

  __asm__ volatile("lidt (%0)" : : "r"(&idtr));
}
void init_idt() {
    //chain here all the interrupts to idt using add_inter
    lidt(idt, sizeof(idt)); }
int kmain() {
    init_idt();
  stack[0] = 0;
  return thing;
}
