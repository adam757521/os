bits 16

; This should receive a data structure containins kernel file start, stage2 file start
_test:
    mov ah, 0x0e
    mov al, 'f'
    int 0x10
    hlt

    mov ax, 0x14a0
    mov ds, ax
    mov bp, sp
    ; jump to protected mode (also possibly get shit from the bios)
    ; TODO: parse bootloader ELF to after kernel ELF (program)
    cli
    mov ax, 0x08
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ax, 0x10
    mov ss, ax
    
    ;mov ax,cr0
    or ax,1
    ;mov cr0 ,ax
    ;a20 line enable fast
    in al, 0x92
    or al, 2
    out 0x92, al
    lgdt [gdtr]
    jmp 0x8:ELF_parsing
    
bits 32
ELF_parsing:
    mov esi , [ebp+0x4] ;esi now points to where stage 2 suppose to be loaded

ELF_struct:
    
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