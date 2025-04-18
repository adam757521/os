#include "../include/asm.h"
#include <stdint.h>

#define VGA_BASE (uint8_t *)0xB8000
#define VGA_CMD 0x3D4
#define VGA_ROW_LEN 0xA0

uint8_t *stream = VGA_BASE;

void clear_console() {
  for (uint8_t *s = VGA_BASE; s < VGA_BASE + VGA_ROW_LEN * 10; s++) {
    s[0] = 0;
  }

  // Disable blinking cursor
  outb(VGA_CMD, 0x0A);
  outb(VGA_CMD + 1, 0x20);
}

void kprint(char *string, uint8_t color) {
  // not thread safe
  volatile uint8_t *s = (uint8_t *)stream;
  while (1) {
    volatile uint8_t c = *string++;
    if (c == '\0')
      break;

    if (c == '\n') {
      s += VGA_ROW_LEN - ((s - VGA_BASE) % VGA_ROW_LEN);
    } else {
      *s++ = c;
      *s++ = color;
    }
  }
  stream = s;
}

void hex(char *buffer, uint32_t num) {
  buffer[0] = '0';
  buffer[1] = 'x';
  for (int i = 2; i < 10; i++) {
    buffer[i] = '0';
  }

  const char *hex_digits = "0123456789ABCDEF";
  for (int i = 9; i >= 2; --i) {
    buffer[i] = hex_digits[num & 0xF];
    num >>= 4;
  }
}
void hex64(char *buffer, uint64_t num) {
  const char hex_digits[] = "0123456789ABCDEF";
  buffer[0] = '0';
  buffer[1] = 'x';

  for (int i = 0; i < 16; ++i) {
    buffer[2 + i] = hex_digits[(num >> (60 - 4 * i)) & 0xF];
  }
}

void debug_hex(uint32_t num) {
  char buffer[12];
  hex(buffer, num);

  buffer[10] = '\n';
  buffer[11] = '\0';

  kprint(buffer, 0x0F);
}

void debug_bin(uint32_t num, char *buf, uint16_t size) {
  uint8_t map = 1 << (size * 8 - 1);
  for (int i = 0; i < size * 8; i++) {
    buf[i] = (num & map) ? '1' : '0';
    map >>= 1;
  }
  buf[size * 8] = '\n';
  buf[size * 8 + 1] = '\0';

  kprint(buf, 0x0F);
}
