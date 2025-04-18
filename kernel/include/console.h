#pragma once

void debug_bin(uint32_t num, char *buf, uint16_t size);
#define bin(num)                                                               \
  {                                                                            \
    char __buf[sizeof(num) * 8 + 2];                                           \
    debug_bin(num, __buf, sizeof(num));                                        \
  }

void debug_hex(uint32_t num);
void clear_console();
void kprint(char *string, uint8_t color);
void kprint_hex(uint64_t decimal);
