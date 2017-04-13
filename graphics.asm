; ##################################################
; Graficki deo posla: pisanje u video memoriju
; ##################################################

segment .code

; ==================================================
; Ispisivanje preostalog vremena
; in:
;     ch = sati, cl = min, dh = sekunde
; ==================================================
_print_time:
    pusha
    mov ax, VID_SEG
    mov es, ax
    mov bx, START_POS
    call _get_time_msg                  ; pretvaramo (ch, cl, dh) u string
    mov si, msg_time_prefix             ; koji dolazi nakon prefiksa 
.print:
    mov al, [si]
    or al, al
    je .end                             ; ispisujemo do nule
    mov [es:bx], al                     ; karakter
    inc bx
    mov [es:bx], byte TIME_COLOR        ; boja
    inc bx
    inc si 
    jmp .print
.end:
    popa
    ret

; ==================================================
; Konvertovanje vremena u poruku
; in:
;     ch = sati, cl = min, dh = sekunde
; out:
;       msg_time = stringovna reprezentacija
; ==================================================
_get_time_msg:
    pusha
    mov si, msg_time                    ; string u koji se upisuje
    mov bl, 10                          ; uvek delimo sa 10
    ; sati
    xor ax, ax ; reset ax
    mov al, ch
    call _put_str
    ; dvotacka
    mov [si], byte ':'
    inc si
    ; minuti
    xor ax, ax ; reset ax
    mov al, cl
    call _put_str
    ; dvotacka
    mov [si], byte ':'
    inc si
    ; sekunde
    xor ax, ax ; reset ax
    mov al, dh
    call _put_str
    popa
    ret

; pomocna podrutina koja upisuje dvocifreni ceo broj u string [si]
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
; Ispisivanje alarma dok zvoni
; ==================================================
_print_ring:
    pusha
    mov ax, VID_SEG
    mov es, ax
    mov bx, START_POS
    mov si, msg_ring                    ; poruka koju zelimo da ispisemo
.print:
    mov al, [si]
    or al, al
    je .end
    mov [es:bx], al                     ; karakter
    inc bx
    mov [es:bx], byte RING_COLOR        ; boja
    inc bx
    inc si 
    jmp .print
.end:
    popa
    ret

; ==================================================
; Ciscenje prostora gde je tekst za alarm
; ==================================================
_clear_vid_mem:
    pusha
    mov ax, VID_SEG
    mov es, ax
    mov bx, START_POS
    mov cx, TEXT_AREA_LEN               ; sirina tekstualnog podrucja
.print:
    mov al, SPACE
    mov [es:bx], al                     ; upisujemo razmake
    inc bx
    mov [es:bx], byte TIME_COLOR
    inc bx
    inc si 
    loop .print
.end:
    popa
    ret

; ==================================================
; Podaci
; ==================================================
segment .data

; poruka koja se ispisuje dok alarm zvoni
msg_ring:           db      '   [    [  [ ALARM ]  ]   ] ', 0

; poruka koja se ispisuje dok traje odbrojavanje
msg_time_prefix:    db      '  Vreme do alarma: '
msg_time:   times 9 db      0

VID_SEG             equ     0B800h          ; pocetak video segmenta
START_POS           equ     0               ; startna vrednost ofseta za video, 1. red
RING_COLOR          equ     0FBh            ; boja za zvono: 1(blink) 111(lightgray bgr) 1011(lcyan foreground)
TIME_COLOR          equ     074h            ; boja za odbrojavanje: 0(no blink) 111(lightgray bgr) 0100(red foreground)
ASCII_ZERO          equ     48              ; ASCII kod za nulu
TEXT_AREA_LEN       equ     30              ; duzina tekstualnog podrucja
SPACE               equ     ' '             ; razmak za brisanje konzole