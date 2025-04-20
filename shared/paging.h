#pragma once

#include <stdint.h>

struct PML4E{
    uint8_t P:1;
    uint8_t RW:1;
    uint8_t US:1;
    uint8_t PWT:1;
    uint8_t PCD:1;
    uint8_t A:1;
    uint8_t ignored:1;
    uint8_t PS:1;
    uint8_t ignored1:4;
    uint32_t addr:20;
    uint32_t reserved:20;
    uint16_t ignored2:11;
    uint8_t XD:1;
    
} __attribute__((packed));