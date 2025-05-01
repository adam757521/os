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

    mov [bpb_pointer], sp 

    ; root dir LBA = Reserved Sectors + sectors per fat * number of fats
    mov ax, [bp + 0x5] ; number of FAT
    mov dx, [bp + 0x19] ; sectors per FATs
    mul dx 
    add ax, [bp+0x3] ; reserved sectors 

    mov [first_data_sector], ax

    mov si, ax
    mov bx, 0x7E00
    ; TODO: root dir is only a single sector
    mov al, 1
    call read_sector_lba

    sub sp, 16
    mov bp, sp
    mov byte [bp+0xD], 0
    mov bx, 0x7e00
search_loop:
    mov al, byte [bx]
    cmp al, 0
    je _hang 

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
    mov di, kernel_file
    mov cx, kernel_file_len
    mov si, bp
    repe cmpsb
    mov si, kernel_file_cluster
    je _file_found

    mov di, stage2_file
    mov cx, stage2_file_len
    mov si, bp
    repe cmpsb
    mov si, stage2_file_cluster
    je _file_found

    jmp next
_file_found:
    mov di, [bx + 20]
    mov [si+0x2], di

    mov di, [bx + 26]
    mov [si], di

    inc byte [bp + 0xD]
    cmp byte [bp + 0xD], 2
    je done
next:
    add bx, 32
    jmp search_loop
done:
    add sp, 16
    mov ax, kernel_file_cluster

    ; possibility: make stage 1.5
    ; TODO: read ELFs to 0x8000
    ; Incase everything wont fit we can make stage2 a binary, not elf
    ; cleanup old shit
    ; jump to protected mode (also possibly get shit from the bios)
    ; TODO: parse bootloader ELF to after kernel ELF (program) 
_hang:
    jmp $

; Traverse (bx dest, dx up 16 bit entry cluster, ax low 16 bit ..)
traverse_fat_copy_file:
    ; Check for stack overflow 
    cmp sp, 0x1000 
    jb _hang

    mov si, [bpb_pointer]

    ; Push all registers
    ; Saving SI, DX (read_sector_lba), ax
    pusha
    ; Needed? 32 bit subtraction
    sub ax, 2
    ; TODO: support more sectors per cluster
    ; Cluster * BPB_SecPerClus
    ; mul byte [si+0x2]
    add ax, [first_data_sector]

    mov si, ax
    mov al, 1
    call read_sector_lba
    popa 
    add bx, 0x200

    ; Do you think im happy writing this code? (1 bit carry flag)
    ; FATOffset (dx:ax) = dx:ax * 4 
    shl ax, 1
    rcl dx, 1
    shl ax, 1
    rcl dx, 1
    
    ; FATOffset / BPB_BytesPerSec
    div word [si+0x0]
    ; BPB_RsvdSecCnt
    add ax, [si+0x3]

    ; Remember the start of the FAT sector is just above the root directory
    pusha
    mov bx, 0x8000
    mov si, ax
    mov al, 1
    call read_sector_lba
    popa

    add dx, 0x8000
    mov si, dx
    ; Pointer to next cluster is stored in SI
    mov ax, [si+0x0]
    mov dx, [si+0x2]

    ; Mask the cluster (high 4 bits are reserved)
    and dx, 0x0FFF
    cmp dx, 0x0FFF
    jne _continue

    cmp ax, 0xFFF8
    jae _return 
_continue:
    ; Production ready code BTW
    call traverse_fat_copy_file
_return:
    ret

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

bpb_pointer dw 0
first_data_sector dw 0
kernel_file db 'kernel.bin' 
kernel_file_len equ $ - kernel_file
stage2_file db 'stage2.bin'
stage2_file_len equ $ - stage2_file
kernel_file_cluster dd 0
stage2_file_cluster dd 0

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
