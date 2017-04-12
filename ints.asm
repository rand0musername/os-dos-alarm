; ##################################################
; Interapt hendleri
; ##################################################

; TODO pomocna rutina koja instalira interapt

segment .code


; ==================================================
; Instalira interapte
; ================================================== 

_inst_all:
    push es
    push si
    mov si, inst
    call _print
    mov ax, cs
    mov ds, ax
    call _inst_2F
    call _inst_1C
    call _inst_09
    pop si
    pop es
    ret

; ==================================================
; Deinstalira interapte
; ================================================== 

_uninst_all:
    push es
    push si
    mov si, uninst
    call _print
    ; es garantovan
    mov ax, es
    mov ds, ax
    call _uninst_2F
    call _uninst_1C
    call _uninst_09
    pop si
    pop es
    ret

; ==================================================
; 2F - MUX upis
; ================================================== 

_inst_2F:
    cli
    ; set ES = 0
    xor ax, ax
    mov es, ax
    ; cuvanje stare rutine
    mov bx, [es:2Fh*4+2]
    mov [ds:loc_2F_seg], bx
    mov bx, [es:2Fh*4]
    mov [ds:loc_2F_off], bx
    ; instalacija nase rutine
    mov ax, cs
    mov [es:2Fh*4+2], ax
    mov bx, irt_2F
    mov [es:2Fh*4], bx
    sti
    ret

; ovo ne treba ovako, TSR ostaje TSR - treba free memorije etc...
_uninst_2F:
    ; vracanje stare rutine
    cli
    xor ax, ax
    mov es, ax
    mov ax, [ds:loc_2F_seg]
    mov [es:2Fh*4+2], ax
    mov dx, [ds:loc_2F_off]
    mov [es:2Fh*4], dx
    sti
    ret


; ==================================================
; 1C - na svaki tajmer update
; ================================================== 

_inst_1C:
    cli
    ; set ES = 0
    xor ax, ax
    mov es, ax
    ; cuvanje stare rutine
    mov bx, [es:1Ch*4+2]
    mov [ds:loc_1C_seg], bx
    mov bx, [es:1Ch*4]
    mov [ds:loc_1C_off], bx
    ; instalacija nase rutine
    mov ax, cs
    mov [es:1Ch*4+2], ax
    mov bx, irt_1C
    mov [es:1Ch*4], bx
    push ds
    pop gs ; zasto ovo?
    sti
    ret

_uninst_1C:
    ; vracanje stare rutine
    cli
    xor ax, ax
    mov es, ax
    mov ax, [ds:loc_1C_seg]
    mov [es:1Ch*4+2], ax
    mov dx, [ds:loc_1C_off]
    mov [es:1Ch*4], dx
    sti
    ret

; ==================================================
; 09 - keyboard za snooze
; ================================================== 

_inst_09:
    cli
    ; set ES = 0
    xor ax, ax
    mov es, ax
    ; cuvanje stare rutine
    mov bx, [es:09h*4+2]
    mov [ds:loc_09_seg], bx
    mov bx, [es:09h*4]
    mov [ds:loc_09_off], bx
    ; instalacija nase rutine
    mov ax, cs
    mov [es:09h*4+2], ax
    mov bx, irt_09
    mov [es:09h*4], bx
    sti
    ret

_uninst_09:
    ; vracanje stare rutine
    cli
    xor ax, ax
    mov es, ax
    mov ax, [ds:loc_09_seg]
    mov [es:09h*4+2], ax
    mov dx, [ds:loc_09_off]
    mov [es:09h*4], dx
    sti
    ret


; ==================================================
; Zapravo rutine, ovo iznad sve moze da se skrati triput ako budem imao vremena
; ==================================================


; ==================================================
; 2F
; ==================================================
irt_2F:
    cmp ah, [cs:loc_2F_id]
    jne .continue
    cmp al, 0
    je .f0
    mov si, err_unknown_function
    call _print
    jmp .continue
.f0:
    mov al, 0FFh
    mov di, signature
    mov dx, cs
    mov es, dx
    iret
.continue:
    push word [cs:loc_2F_seg]
    push word [cs:loc_2F_off]
    retf
    ; mozda treba ceo int 1Ch preseliti ovde u .f1?


; ==================================================
; 1C
; ==================================================
irt_1C:
    pusha
    mov ax, cs
    mov ds, ax
    cmp [cs:state], byte STATE_OVER
    je .end
    cmp [cs:state], byte STATE_RINGING
    je .ringing
.active:
    ; reentrancy
    mov ax, [cs:indos_seg]
    mov es, ax
    mov bx, [cs:indos_off]
    mov al, byte [es:bx]
    or al, al
    jnz .end ; in use
    ; you can go on
    mov ah, 2Ch
    int 21h
    ; ch = sati sada, cl = min sada, dh = sekunde sada
    call _diff_time
    ; ch = sati diff, cl = min diff, dh = sekunde diff
    or ch, ch
    jnz .draw_prep
    or cl, cl
    jnz .draw_prep
    or dh, dh
    jnz .draw_prep
    ; START RINGING FROM NEXT TURN
    mov [cs:state], byte STATE_RINGING
    mov [cs:ticks_left], byte TICKS_RINGING
.draw_prep:
    call _clear_vid_mem
    call _print_time
    jmp .end
.ringing:
    mov al, [cs:ticks_left]
    or al, al
    jz .set_over
    dec al
    mov [cs:ticks_left], byte al
    call _clear_vid_mem
    call _print_ring
    jmp .end
.set_over:
    mov [cs:state], byte STATE_OVER
    ; TODO: da se sam deinstalira pa da ne mora stop
    call _clear_vid_mem
    jmp .end
.end:
    popa
    iret

; ==================================================
; 09 - SNOOZE TODO
; ==================================================
irt_09:
    pusha                  
    in al, KBD
    cmp al, SNOOZE_KEY
    jne .continue
    cmp [cs:state], byte STATE_RINGING
    jne .continue
.snooze:
    mov [cs:state], byte STATE_ACTIVE
    call _snooze_time
.continue:
    popa
    push word [cs:loc_09_seg]
    push word [cs:loc_09_off]
    retf
    

; ==================================================
; Importi
; ==================================================
%include "utils.asm"
%include "int_util.asm"
%include "graphics.asm"


; ==================================================
; Podaci
; ==================================================

segment .data


err_unknown_function: db 'Nepoznat kod funkcije.', 0

inst: db 'Instalirao sve.', 0
uninst: db 'Deinstalirao sve.', 0

loc_1C_seg: dw 0
loc_1C_off: dw 0
loc_09_seg: dw 0
loc_09_off: dw 0
loc_2F_seg: dw 0
loc_2F_off: dw 0

loc_2F_id: db 0

indos_seg: dw 0
indos_off: dw 0


state: db 0
STATE_ACTIVE equ 1
STATE_RINGING equ 2
STATE_OVER equ 3

ticks_left: db 0


TICKS_RINGING equ 100
SPACE equ ' '

ZEZ: db 'ZEZ TEST', 0                  
SNOOZE_KEY equ 's'
KBD            equ 060h   