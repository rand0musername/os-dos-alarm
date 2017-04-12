
segment .code

; ==================================================
; 09 - VIDEO MEM
; ==================================================

; ==================================================
; Stampa vreme u video memoriju
; in:
;   ; ch = sati diff, cl = min diff, dh = sekunde diff
; ==================================================
_print_time:
    pusha
    mov ax, VID_SEG
    mov es, ax
    mov bx, START_POS
    call _get_time_msg ; u si
    mov si, msg_time_prefix
.print:
    mov al, [si]
    or al, al
    je .end
    mov [es:bx], al
    inc bx
    mov [es:bx], byte TIME_COLOR
    inc bx
    inc si 
    jmp .print
.end:
    popa
    ret


; ==================================================
; Konvertuje vreme u poruku
; in:
;   ; ch = sati diff, cl = min diff, dh = sekunde diff
; out:
;       msg_time = string
; ==================================================
_get_time_msg:
    pusha
    ; pripremi string u koji se upisuje
    mov si, msg_time 
    mov bl, 10 ; uvek delimo sa 10
    xor ax, ax ; 0 za svaki slucaj
    ; SATI
    mov al, ch
    call _put_str
    ; dvotacka
    mov [si], byte ':'
    inc si
    ; MINUTI
    mov al, cl
    call _put_str
    ; dvotacka
    mov [si], byte ':'
    inc si
    ; SEKUNDE
    mov al, dh
    call _put_str
    popa
    ret

_put_str:
    div bl
    mov [si], al
    add [si], byte ASCII_ZERO
    inc si
    mov [si], ah
    add [si], byte ASCII_ZERO
    inc si
    ret



; ==================================================
; Stampa ring u video memoriju, menja boju naa %2
; ==================================================
_print_ring:
    pusha
    mov ax, VID_SEG
    mov es, ax
    mov bx, START_POS
    mov si, msg_ring
.print:
    mov al, [si]
    or al, al
    je .end
    mov [es:bx], al
    inc bx
    mov [es:bx], byte RING_COLOR
    inc bx
    inc si 
    jmp .print
.end:
    popa
    ret

; ==================================================
; Clearuje prostor gde je alarm
; ==================================================
_clear_vid_mem:
    pusha
    mov ax, VID_SEG
    mov es, ax
    mov bx, START_POS
    mov cx, 30
.print:
    mov al, SPACE
    mov [es:bx], al
    inc bx
    mov [es:bx], byte TIME_COLOR
    inc bx
    inc si 
    loop .print
.end:
    popa
    ret


segment .data

msg_ring: db '   [    [  [ ALARM ]  ]   ] ', 0


VID_SEG     equ     0B800h ; pocetak video segmenta
START_POS   equ     0    ; startna vrednost ofseta za video, 3. red
RING_COLOR  equ     0FBh   ; boja: 1(blink) 111(lightgray bgr) 1011(lblue fore)
TIME_COLOR  equ     074h   ; boja: 0(no blink) 111(lightgray bgr) 0100(lblue fore)
ASCII_ZERO  equ     48


msg_time_prefix: db '  Vreme do alarma: '
msg_time: times 9 db 0