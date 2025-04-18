#pragma once

#include "types.h"

static inline __attribute__((always_inline)) void outb(uint16_t port, uint8_t val)
{
    __asm__ volatile ( "outb %b0, %w1" : : "a"(val), "Nd"(port) : "memory" );
}

static inline __attribute__((always_inline)) uint16_t inb(uint16_t port)
{
    uint16_t code;
    __asm__ volatile ( "inb %w1, %b0" : "=a"(code) : "Nd"(port));
    return code;
}

