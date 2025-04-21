;very hashoov lasim lev that both the bootloader and the filesystem are together combined on the same .img file 
[BITS 16]
[ORG 0x7C00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov [boot_drive], dl

    ; Load sector 0 (כבר נטען על ידי הביוס כי שילבתי את הדיסקים)
    ; So just parse the BPB at 0x7C00 + 0x0B
    mov si, 0x7C0B
    mov di, bpb_struct
    mov cx, 25         ; Number of bytes we care about from BPB
  rep movsb ; לולאה CX:זה הסופר SI:המקום ממנו נקרא DI:המקום אליו נקרא

    ; Calculate root directory LBA
    mov ax, [bpb_struct + 14]   ; reserved sectors
    mov bx, [bpb_struct + 22]   ; sectors per FAT
    xor dx, dx
    mov dl, [bpb_struct + 16]   ; number of FATs
    mul dx
    add ax, bx
    mov [root_dir_lba], ax
    ;gammaaaaaa
    ; Calculate root dir size in sectors = (root_entries * 32) / bytes_per_sector
    mov ax, [bpb_struct + 17]   ; root entries
    mov cx, 32
    mul cx
    xor dx, dx
    mov bx, [bpb_struct + 11]   ; bytes per sector
    div bx
    mov [root_dir_sectors], ax

    ; Load root directory sectors
    mov si, 0
load_root_dir:
    mov ax, [root_dir_lba]
    add ax, si
    call read_sector
    inc si
    cmp si, [root_dir_sectors]
    jl load_root_dir

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
    mov [file_cluster], ax
    ;cyberrrrrr
    ; Load cluster into 0x1000
    mov bx, 0x1000
    call load_cluster
    jmp 0x1000                  ; jump to kernel

; Converts cluster # in AX to LBA in AX
cluster_to_lba:
    sub ax, 2
    xor dx, dx
    mov dl, [bpb_struct + 13]  ; sectors per cluster
    mul dx
    add ax, [root_dir_lba]
    add ax, [root_dir_sectors]
    ret

; Reads sector AX into 0x7E00
read_sector:
    push ax
    mov bx, 0x7E00
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, al
    mov dh, 0
    mov dl, [boot_drive]
    int 0x13
    pop ax
    ret

load_cluster:
    push ax
    mov ax, [file_cluster]
    call cluster_to_lba
    call read_sector
    ; Copy from 0x7E00 to 0x1000
    mov si, 0x7E00
    mov di, bx
    mov cx, 512
    rep movsb
    pop ax
    ret

filename db 'KERNEL  BIN'
boot_drive db 0
file_cluster dw 0
root_dir_lba dw 0
root_dir_sectors dw 0
;decided to treat the entire BPB as a one struct and to not seperate it to labels
bpb_struct:
    ; Offsets:
    ; 0x00 - bytes per sector       (2 bytes)
    ; 0x02 - sectors per cluster    (1 byte)
    ; 0x03 - reserved sectors       (2 bytes)
    ; 0x05 - number of FATs         (1 byte)
    ; 0x06 - root entries           (2 bytes)
    ; 0x08 - total sectors (16b)    (2 bytes)
    ; 0x0A - media descriptor       (1 byte)
    ; 0x0B - sectors per FAT        (2 bytes)
    ; 0x0D - sectors per track      (2 bytes)
    ; 0x0F - number of heads        (2 bytes)
    ; 0x11 - hidden sectors         (4 bytes)
    times 25 db 0

times 510 - ($-$$) db 0
dw 0xAA55

