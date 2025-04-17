#pragma once

#include "types.h"

struct idt_entry {
  uint16_t offset_low;  // 0-15 bits of the offset
  uint16_t selector;    // code segement selector
  uint8_t zero;         // unuesd
  uint8_t type;         // gate,dpl,fields
  uint16_t offset_high; // bits 16-31 of the offset
};

struct interrupt_frame {
  uint32_t eip;
  uint32_t cs;
  uint32_t rflags;
  uint32_t esp;
  uint32_t ss;
};

void pic_init();
void idt_init();
