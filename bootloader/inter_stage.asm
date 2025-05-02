bits 16

;stack frame -
; offset (size)
;0x0 (2) - 0x14a0 (segment)
;2 (4) - 0x14c00 (end of inter)
;6 (4) - 0x14a00 (start of inter)
;10 (4) - 0x14800 (start of stage2)
; start of kernel is always 0x8000

_start:
    mov bp, sp
    mov ax, word [bp]
    mov es, ax
    mov ds, ax

    ; jump to protected mode (also possibly get shit from the bios)
    ; TODO: parse bootloader ELF to after kernel ELF (program)
    lgdt [gdtr]

    mov ax, 0x08
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ax, 0x10
    mov ss, ax
    
    mov ax, cr0
    or ax,1
    mov cr0, ax
    ;a20 line enable fast
    in al, 0x92
    or al, 2
    out 0x92, al
    lgdt [gdtr]
    jmp 0x8:ELF_parsing
    
bits 32
ELF_parsing:
    mov esi , [ebp+0x10] ;esi now points to where stage 2 suppose to be loaded


    
gdt:
    dq 0
_general_segment:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x9B
_general_flag:
    db 0xCF
    db 0x00
_stack_segment:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x97
_stack_flag:
    db 0xCF
    db 0x00
gdt_end:
gdtr:
    dw gdt_end - gdt - 1
    dd gdt