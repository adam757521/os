bits 16
org 0x7c00

start:
    cli

    xor ax, ax
    mov ss, ax
    mov sp, 0x7c00

    mov si, dap 
    mov ah, 42h
    mov dl, 80h
    int 13h

    ; TODO: switch this to use only 16 bit registers
    xor ax, ax
    mov ds, ax
    mov edx, dword [0x7E08]
    mov ebx, dword [0x7E0C]

    add edx, ebx
    ;mov dword [data_end], eax
    mov ebx, dword [0x7E00]
    sub edx, ebx

    ; TODO: dynamic sectors
    ;cmp edx, 488 
    ;jg error

    mov si, 0x7E1C
    mov di, 0x10
    xor ax, ax
    mov ds, ax
    not ax
    mov es, ax

    test dx, 1
    jz div

    inc dx
div:
    shr dx, 1

    mov cx, dx
copy:
    movsw
    loop copy

    xor ax, ax
    mov ds, ax
    lgdt [gdtr]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp 0x08:protected_mode
bits 32
protected_mode:
    mov ax, 0x08
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ax, 0x10
    mov ss, ax

    mov esp, dword [0x7E18]

    jmp 0x100000
check_a20:
    push ds
    push si

    xor ax, ax
    mov al, byte [es:0x1] 
    push ax

    mov si, 0x0011
    mov ax, 0xFFFF
    mov ds, ax
    ; 0x100001
    
    mov byte [es:0x1], 0x00
    mov byte [ds:si], 0xFF

    cmp byte [es:0x1], 0xFF

    pop ax
    mov byte [es:0x1], al 

    pop si
    pop ds

    mov ax, 1
    jne _enabled
    
    mov ax, 0
_enabled:
    ret
error:
    mov ah, 0x0e
    mov al, 'f'
    int 0x10
    hlt
gdt:
    dq 0
_general_segment:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x9B
    db 0xCF
    db 0x00
_stack_segment:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x97
    db 0xCF
    db 0x00
gdt_end:
gdtr:
    dw gdt_end - gdt - 1
    dd gdt
dap:
    db 0x10 ; size
    db 0x00
    dw 0x0002 ; sectors to read
    dw 0x7E00 ; offset (temporary buffer)
    dw 0x0000 ; segment 
    dd 0x00000001 ; LBA lower 32
    dd 0x00000000 ; LBA upper 32
data_end:
    dd 0
size:
    dd 0

times 510 - ($-$$) db 0
dw 0xaa55
