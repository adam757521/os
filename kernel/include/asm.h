#pragma once

#include "types.h"

static inline __attribute__((always_inline)) void outb(uint16_t port, uint8_t val) {
    __asm__ volatile ( "outb %b0, %w1" : : "a"(val), "Nd"(port) : "memory" );
}

