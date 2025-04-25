[BITS 16]
[ORG 0x7C00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    sub sp, 0x30
    mov bp, sp

    ; Read BPB
    mov bx, 0x7E00
    mov si, 0x0
    mov al, 1
    call read_sector_lba

    mov si, 0x7E0B
    mov di, sp 
    ; Size of bpb struct
    mov cx, 0x28
    ; DI: dst, SI: src, CX: iterator
    rep movsb

    ; root dir LBA = Reserved Sectors + sectors per fat * number of fats
    mov ax, [bp + 0x5] ; number of FAT
    mov dx, [bp + 0x19] ; sectors per FATs
    mul dx 
    add ax, [bp + 0x3] ; reserved sectors 

    mov si, ax
    mov bx, 0x7E00
    ; TODO: root dir is only a single sector
    mov al, 1
    call read_sector_lba

    sub sp, 16
    mov bp, sp
    mov bx, 0x7e00
search_loop:
    mov al, byte [bx]
    cmp al, 0
    je done

    cmp al, 0xE5
    je next

    cmp byte [bx+11], 0x0f
    jne sfn
    
    mov si, bx
    inc si
    mov di, bp
    mov cx, 5
    call copy_utf16

    mov si, bx
    add si, 14
    mov cx, 6
    call copy_utf16

    mov si, bx
    add si, 28
    mov cx, 2
    call copy_utf16

    jmp next
sfn:
    cmp byte [bp], 0x0
    jne name_set

    ; TODO: support short file name

name_set:
    ; check if our file was found
    ; if not, continue
    ; if found, is the second found
    ; can keep count, no duuplicate
    mov di, kernel_file
    mov cx, kernel_file_len
    mov si, bp
    repe cmpsb
    jne next

    ;mov dx, [bx + 20]
    ;mov ax, [bx + 26]
    mov dx, 0xABCD
    mov ax, 0x5678

    ; Do you think im happy writing this code? (1 bit carry flag)
    shl ax, 1
    rcl dx, 1

    shl ax, 1
    rcl dx, 1

    xor ax, ax


    ;mov ax, [bx + 28]

    ; test if two strings were found

    ;gammaaaaaa
next:
    add bx, 32
    jmp search_loop
done:
    add sp, 16
    jmp $

traverse_fat_copy_file:
    ; read the cluster to a pointer
    ; calculate next cluster
    ; loop

; Read(bx dest, si LBA, al sector_count)
read_sector_lba:
    mov [dapack+0x8], si
    mov [dapack+0x2], al
    mov [dapack+0x4], bx

    xor ax, ax
    mov ds, ax
    mov si, dapack 
    mov ah, 0x42
    mov dl, 0x80
    int 0x13
    ret
; cx count, si source, di dest
copy_utf16:
    movsb
    add si, 1
    loop copy_utf16
    ret

kernel_file db 'kernel.bin' 
kernel_file_len equ $ - kernel_file

dapack:
db 0x10
db 0
dw 0
dw 0xFFFF
dw 0
dd 0 
dd 0
times 510 - ($-$$) db 0
dw 0xAA55
