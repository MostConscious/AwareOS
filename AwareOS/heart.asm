[bits 16]
[org 0x7c00]

start:
    mov ax, 0x0003
    int 0x10

    mov ah, 0x02
    mov al, 8
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0
    mov bx, 0x7E00
    int 0x13
    jc  .error

    jmp 0x7E00

.error:
    mov si, err_msg
    call print_string
    jmp hang

print_string:
    mov ah, 0x0e
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

hang:
    jmp hang

err_msg db "Disk read error", 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55
