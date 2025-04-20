bits 16
org 0x7C00

start:
    cli
    
    mov ax, 0x7E0
    mov es, ax 

    mov ah, 02h
    mov al, 1 ; sectors to read
    mov ch, 0
    mov cl, 1 ; sector
    mov dh, 0 ; head
    ;mov dl, 0x80
    mov bx, 0
    int 13h

    ; lol dont use magic
    mov eax, [BPB_reserved_sectors]
    mov eax, [BPB_sectors_per_cluster]
    mov eax, [BPB_bytes_per_sector]
    mov eax, [BPB_cluster_root]

    xor eax, eax

BPB:
    dw 0
    db 0
    dq 8
BPB_bytes_per_sector:
    dw 0
BPB_sectors_per_cluster:
    db 0
BPB_reserved_sectors:
    dw 0
BPB_FAT_count:
    db 0
BPB_ROOT_count:
    dw 0
    dw 0
    db 0
    dw 0
BPB_sectors_per_track:
    dw 0
BPB_head_count:
    dw 0
    dd 0
BPB_sector_count:
    dd 0
BPB_sectors_per_fat:
    dd 0
BPB_flags:
    dw 0
    dw 0
BPB_cluster_root:
    dd 0
BPB_fsinfo_sector:
    dw 0
    dw 0
    dq 0
    dd 0
    db 0
    db 0
    db 0
    dd 0
    dq 0
    dw 0
    db 0


times 510 - ($-$$) db 0
dw 0xaa55