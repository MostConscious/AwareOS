[bits 16]
[org 0x7E00]

shell:
    mov si, welcome
    call print_string
    mov si, prompt
    call print_string

.loop:
    mov ah, 0x00
    int 0x16

    cmp al, 27
    je  .exit
    cmp al, 13
    je  .enter
    cmp al, 8
    je  .backspace

    test al, al
    jz  .arrow

    cmp word [buf_len], 63
    jae .loop

    mov bx, [buf_len]
    mov [buffer + bx], al
    inc word [buf_len]
    mov ah, 0x0e
    int 0x10
    jmp .loop

.arrow:
    cmp ah, 0x48
    je  .up
    cmp ah, 0x50
    je  .down
    jmp .loop

.up:
    mov ax, [hist_pos]
    inc ax
    cmp ax, [hist_count]
    ja  .loop
    cmp ax, 8
    ja  .loop
    mov [hist_pos], ax

    mov bx, [hist_count]
    sub bx, ax
    and bx, 7
    shl bx, 6
    mov si, hist_buf
    add si, bx
    mov di, buffer
    push ds
    pop es
    mov cx, 64
    rep movsb

    mov bx, 0
.stl_u:
    cmp byte [buffer + bx], 0
    je  .stl_u_done
    inc bx
    jmp .stl_u
.stl_u_done:
    mov [buf_len], bx

    call redraw_line
    jmp .loop

.down:
    mov ax, [hist_pos]
    cmp ax, 0
    je  .loop
    dec ax
    mov [hist_pos], ax

    cmp ax, 0
    je  .down_empty

    mov bx, [hist_count]
    sub bx, ax
    and bx, 7
    shl bx, 6
    mov si, hist_buf
    add si, bx
    mov di, buffer
    push ds
    pop es
    mov cx, 64
    rep movsb

    mov bx, 0
.stl_d:
    cmp byte [buffer + bx], 0
    je  .stl_d_done
    inc bx
    jmp .stl_d
.stl_d_done:
    mov [buf_len], bx

    call redraw_line
    jmp .loop

.down_empty:
    mov byte [buffer], 0
    mov word [buf_len], 0
    call redraw_line
    jmp .loop

.backspace:
    cmp word [buf_len], 0
    je  .loop
    dec word [buf_len]
    mov bx, [buf_len]
    mov byte [buffer + bx], 0
    mov ah, 0x0e
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    jmp .loop

.enter:
    mov bx, [buf_len]
    mov byte [buffer + bx], 0

    mov ah, 0x0e
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10

    call save_hist
    call execute

    mov word [buf_len], 0
    mov si, prompt
    call print_string
    jmp .loop

.exit:
    mov ax, 0x0003
    int 0x10
    mov si, msg_bye
    call print_string
    jmp hang

hang:
    jmp hang

print_string:
    mov ah, 0x0e
.loop_ps:
    lodsb
    cmp al, 0
    je .done_ps
    int 0x10
    jmp .loop_ps
.done_ps:
    ret

print_char:
    push ax
    mov ah, 0x0e
    int 0x10
    pop ax
    ret

print_bcd:
    push ax
    shr al, 4
    add al, 0x30
    call print_char
    pop ax
    and al, 0x0F
    add al, 0x30
    call print_char
    ret

print_2digits:
    xor ah, ah
    mov bl, 10
    div bl
    push ax
    add al, 0x30
    call print_char
    pop ax
    mov al, ah
    add al, 0x30
    call print_char
    ret

bcd_to_dec:
    mov bl, al
    shr al, 4
    and bl, 0x0F
    mov ah, 10
    mul ah
    add al, bl
    ret

set_cur:
    mov ah, 0x02
    mov bh, 0
    int 0x10
    ret

put_c:
    mov ah, 0x0e
    int 0x10
    ret

redraw_line:
    mov al, 13
    call print_char
    mov cx, 79
.rl:
    mov al, ' '
    call print_char
    loop .rl
    mov al, 13
    call print_char
    mov si, prompt
    call print_string
    mov si, buffer
    call print_string
    ret

save_hist:
    cmp word [buf_len], 0
    je  .sh_done
    mov ax, [hist_count]
    mov bx, ax
    and bx, 7
    shl bx, 6
    mov di, hist_buf
    add di, bx
    mov si, buffer
    push ds
    pop es
    mov cx, 64
    rep movsb
    inc word [hist_count]
    mov word [hist_pos], 0
.sh_done:
    ret

draw_px:
    mov dh, [py]
    mov dl, [px]
    call set_cur
    mov al, '@'
    call put_c
    ret

erase_px:
    mov dh, [py]
    mov dl, [px]
    call set_cur
    mov al, ' '
    call put_c
    ret

draw_border:
    mov dh, 0
    mov dl, 0
    call set_cur
    mov cx, 80
    mov al, '='
.dbt:
    call put_c
    loop .dbt
    mov dh, 24
    mov dl, 0
    call set_cur
    mov cx, 80
    mov al, '='
.dbb:
    call put_c
    loop .dbb
    ret

strcmp:
    mov di, buffer
.loop_cmp:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_equal
    cmp al, 0
    je  .equal
    inc si
    inc di
    jmp .loop_cmp
.equal:
    ret
.not_equal:
    ret

execute:
    mov si, cmd_help
    call strcmp
    je  .do_help
    mov si, cmd_clear
    call strcmp
    je  .do_clear
    mov si, cmd_AboutMe
    call strcmp
    je  .do_AboutMe
    mov si, cmd_time
    call strcmp
    je  .do_time
    mov si, cmd_play
    call strcmp
    je  .do_play
    mov si, cmd_exit
    call strcmp
    je  .do_exit
    mov si, msg_unknown
    call print_string
    ret

.do_help:
    mov si, msg_help
    call print_string
    ret

.do_clear:
    mov ax, 0x0003
    int 0x10
    mov si, welcome
    call print_string
    ret

.do_AboutMe:
    mov si, msg_AboutMe
    call print_string
    ret

.do_exit:
    mov ax, 0x0003
    int 0x10
    mov si, msg_bye
    call print_string
    jmp hang

.do_time:
    mov si, msg_tz
    call print_string
    mov word [buf_len], 0
.read_tz:
    mov ah, 0x00
    int 0x16
    cmp al, 27
    je  .tz_cancel
    cmp al, 13
    je  .parse_tz
    cmp al, 8
    je  .tz_bksp
    mov bx, [buf_len]
    cmp bx, 3
    jae .read_tz
    mov [buffer + bx], al
    inc word [buf_len]
    mov ah, 0x0e
    int 0x10
    jmp .read_tz
.tz_bksp:
    cmp word [buf_len], 0
    je .read_tz
    dec word [buf_len]
    mov bx, [buf_len]
    mov byte [buffer + bx], 0
    mov ah, 0x0e
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    jmp .read_tz
.tz_cancel:
    mov al, 13
    call print_char
    mov al, 10
    call print_char
    ret
.parse_tz:
    mov bx, [buf_len]
    mov byte [buffer + bx], 0
    mov al, 13
    call print_char
    mov al, 10
    call print_char
    mov si, buffer
    mov byte [tz_sign], 0
    xor cx, cx
    lodsb
    cmp al, '-'
    jne .pz_plus
    mov byte [tz_sign], 1
    jmp .pz_digits
.pz_plus:
    cmp al, '+'
    je .pz_digits
    dec si
.pz_digits:
    lodsb
    cmp al, 0
    je .pz_apply
    sub al, '0'
    cmp al, 9
    ja .pz_bad
    push ax
    mov ax, cx
    cmp ax, 30
    ja .pz_bad_pop
    mov bx, 10
    mul bx
    mov cx, ax
    pop ax
    xor ah, ah
    add cx, ax
    jmp .pz_digits
.pz_bad_pop:
    pop ax
.pz_bad:
    mov si, msg_badtz
    call print_string
    ret
.pz_apply:
    cmp cx, 23
    ja  .pz_bad
    mov [tz_offset], cx
    jmp .live_loop
.live_loop:
    mov ah, 0x01
    int 0x16
    jz  .live_render
    mov ah, 0x00
    int 0x16
    cmp al, 13
    je  .live_exit
    jmp .live_render
.live_render:
    mov ah, 0x02
    int 0x1A
    mov [last_sec], dh
    mov al, ch
    call bcd_to_dec
    mov bl, al
    mov ax, [tz_offset]
    cmp byte [tz_sign], 0
    jne .live_sub
    add bl, al
    jmp .live_bounds
.live_sub:
    sub bl, al
.live_bounds:
    cmp bl, 24
    jl  .live_low
    sub bl, 24
    jmp .live_print
.live_low:
    cmp bl, 0
    jge .live_print
    add bl, 24
.live_print:
    mov si, msg_time
    call print_string
    mov al, bl
    call print_2digits
    mov al, ':'
    call print_char
    mov al, cl
    call print_bcd
    mov al, ':'
    call print_char
    mov al, dh
    call print_bcd
.live_wait:
    mov ah, 0x02
    int 0x1A
    cmp dh, [last_sec]
    je  .live_wait
    mov al, 13
    call print_char
    jmp .live_loop
.live_exit:
    mov al, 13
    call print_char
    mov al, 10
    call print_char
    ret

.do_play:
    mov ax, 0x0003
    int 0x10
    mov ah, 0x01
    mov cx, 0x2607
    int 0x10
    call draw_border
    mov dh, 1
    mov dl, 1
    call set_cur
    mov si, play_help
    call print_string
    mov byte [px], 40
    mov byte [py], 12
    call draw_px
.play_loop:
    mov ah, 0x00
    int 0x16
    cmp al, 27
    je  .play_exit
    cmp ah, 0x48
    je  .p_up
    cmp ah, 0x50
    je  .p_down
    cmp ah, 0x4B
    je  .p_left
    cmp ah, 0x4D
    je  .p_right
    jmp .play_loop
.p_up:
    call erase_px
    dec byte [py]
    cmp byte [py], 2
    jae .p_up_ok
    inc byte [py]
.p_up_ok:
    call draw_px
    jmp .play_loop
.p_down:
    call erase_px
    inc byte [py]
    cmp byte [py], 23
    jbe .p_dn_ok
    dec byte [py]
.p_dn_ok:
    call draw_px
    jmp .play_loop
.p_left:
    call erase_px
    dec byte [px]
    cmp byte [px], 1
    jae .p_lf_ok
    inc byte [px]
.p_lf_ok:
    call draw_px
    jmp .play_loop
.p_right:
    call erase_px
    inc byte [px]
    cmp byte [px], 78
    jbe .p_rt_ok
    dec byte [px]
.p_rt_ok:
    call draw_px
    jmp .play_loop
.play_exit:
    mov ax, 0x0003
    int 0x10
    mov ah, 0x01
    mov cx, 0x0607
    int 0x10
    mov si, welcome
    call print_string
    ret

welcome     db "AwareOS shell v1.0", 13, 10
db "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=", 13, 10, 0
prompt      db "> ", 0
cmd_help    db "help", 0
cmd_clear   db "clear", 0
cmd_AboutMe db "AboutMe", 0
cmd_time    db "time", 0
cmd_play    db "play", 0
cmd_exit    db "exit", 0

msg_help    db "Commands:", 13, 10
            db "  help    - show", 13, 10
            db "  clear   - clear screen", 13, 10
            db "  AboutMe - about the project", 13, 10
            db "  time    - live clock with timezone", 13, 10
            db "  play    - arrow demo", 13, 10
            db "  exit    - quit", 13, 10, 0

msg_AboutMe db "AwareOS v1.0 - 16-bit OS on assembler", 13, 10, 0
msg_unknown db "Unknown command", 13, 10, 0
msg_bye     db "Goodbye!", 13, 10, 0
msg_tz      db "Timezone offset (e.g. +3 or -5): ", 0
msg_badtz   db "Bad offset. Use -23..+23", 13, 10, 0
msg_time    db "Time: ", 0
play_help   db "Arrows to move, ESC to exit", 0

tz_sign     db 0
tz_offset   dw 0
last_sec    db 0
px          db 40
py          db 12

hist_buf    times 8*64 db 0
hist_count  dw 0
hist_pos    dw 0

buffer      times 64 db 0
buf_len     dw 0
