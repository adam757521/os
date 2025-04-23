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

    ;mov si, dapack 
    ;mov ah, 0x42
    ;mov dl, 0x80
    ;int 0x13

    mov ah, 8h
    mov dl, 0x80
    int 13h

    inc dh
    and cl, 0x3F
    xor dl, dl
    or dl, cl
    ; first byte - head
    ; second byte - SPT
    mov [bp], dx

    mov bx, 0x7E00
    mov si, 0x1FA2
    mov al, 1
    call read_sector_lba

    mov si, 0x7E0B
    mov di, sp 
    ; Size of bpb struct
    mov cx, 0x28
    ; DI: dst, SI: src, CX: iterator
    rep movsb

    ; Calculate root directory LBA
    ; LBA = Reserved Sectors + sectors per fat * number of fats
    mov ax, [bp + 0x5 + 0x4] ; number of FAT
    mov dx, [bp + 0x19 +0x4] ; sectors per FATs
    mul dx 
    add ax, [bp + 0x3 +0x4] ; reserved sectors 

    ;temp - root directories
    mov bx, [bp + 0x6 + 0x4]

    ;mov cl, ax
    mov bx, 0x7E00
    mov al, 1
    call read_sector

    ;gammaaaaaa

    ; Load root directory sectors
    mov si, 0
load_root_dir:
    ;mov ax, [root_dir_lba]
    add ax, si
    ;call read_sector
    inc si
    ;cmp si, [root_dir_sectors]
    ;jl load_root_dir

    ; Search for filename "KERNEL  BIN"
    mov di, 0x7E00              ; start of root dir
search_loop:
    mov si, filename
    push di
    mov cx, 11
    repe cmpsb
    pop di
    je file_found
    add di, 32
    cmp di, 0x7E00 + 512
    jl search_loop

not_found:
    jmp $

file_found:
    ; DI points to directory entry
    mov ax, [di + 26]           ; first cluster
    ;mov [file_cluster], ax
    ;cyberrrrrr
    ; Load cluster into 0x1000
    mov bx, 0x1000
    ;call load_cluster
    jmp 0x1000                  ; jump to kernel

; Converts cluster # in AX to LBA in AX
cluster_to_lba:
    sub ax, 2
    xor dx, dx
    ;mov dl, [bpb_struct + 13]  ; sectors per cluster
    mul dx
    ;add ax, [root_dir_lba]
    ;add ax, [root_dir_sectors]
    ret

; Read (bx dest, si lba, al sector_count)

; Read(bx dest, al sector_count, cl start_sector, ch cylinder, dh head)
read_sector:
    mov ah, 0x02
    mov dl, 0x80
    int 0x13
    ret

load_cluster:
    push ax
    ;mov ax, [file_cluster]
    ;call cluster_to_lba
    ;call read_sector
    ; Copy from 0x7E00 to 0x1000
    mov si, 0x7E00
    mov di, bx
    mov cx, 512
    rep movsb
    pop ax
    ret

filename db 'KERNEL  BIN'
file_cluster dw 0
dapack:
db 0x10
db 0
dw 16
dw 0x7E00
dw 0
dd 8098
dd 0

times 510 - ($-$$) db 0
dw 0xAA55

