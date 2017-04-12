; ##################################################
; Pomocne funkcije
; ##################################################

; ==================================================
; Ispis inta na ekran (BIOS)
; in:
;      ax = int koji zelimo da se ispise
; ================================================== 

_print_int:
    pusha
    mov cx, 0           ; brojac cifara
    mov bx, 10          ; delicemo sa 10
.divide:
    mov dx, 0           ; priprema za deljenje
    div bx              ; ax:dx / bx = ax(dx)
    push dx             ; ostatak na stack
    inc cx              ; povecanje brojaca cifri
    or ax, ax           ; provera da li ima jos cifara
    jnz .divide
.print:
    pop ax
    add al, ASCII_ZERO  ; zelimo da ispisemo char 0 a ne broj 0
    mov ah, 0Eh         ; BIOS 10h: ah = 0eh (Teletype Mode), al = znak koji se ispisuje
    int 10h             ; ispis
    loop .print
.end:
    mov al, ' '                        
    mov  ah, 0Eh                      ; BIOS 10h: ah = 0eh (Teletype Mode), al = znak koji se ispisuje
    int  10h
    popa
    ret


; ==================================================
; Printa novi red
; ================================================== 
_newline:
    pusha
    mov al, 0Dh                        
    mov  ah, 0Eh                      ; BIOS 10h: ah = 0eh (Teletype Mode), al = znak koji se ispisuje
    int  10h
    mov al, 0Ah                        
    mov  ah, 0Eh                      ; BIOS 10h: ah = 0eh (Teletype Mode), al = znak koji se ispisuje
    int  10h
    popa
    ret

; ==================================================
; Duzina stringa
; in:
;      si = string terminiran nulom
; out:
;      cx = duzina
; ================================================== 

_strlen:
      pusha
      cld
      xor cx, cx
.count:
      lodsb                             ; ucitava znakove do nailaska prve nule
      or   al, al                       ; ako smo dosli do kraja zavrsava metodu
      jz  .end                         
      inc cx
.end:
      popa
      ret   

; ==================================================
; Ispis poruke na ekran (BIOS)
; in:
;      si = string terminiran nulom koji se ispisuje
; ================================================== 

_print:
      pusha
      cld
.print_char:
      lodsb                             ; ucitava znakove do nailaska prve nule
      or   al, al                       ; ako smo dosli do kraja zavrsava metodu
      jz  .end                         
      mov  ah, 0Eh                      ; BIOS 10h: ah = 0eh (Teletype Mode), al = znak koji se ispisuje
      int  10h
      jmp .print_char     
.end:
      popa
      ret    

; ==================================================
; Parsiranje vremena
; in:
;      di = pocetak stringa vremena HH:MM:SS
; out:
;      time, time+1, time+2 = parsovano vreme
;      valid_time = validno parsovano
; ================================================== 

_parse_time:
    mov si, time
    mov [valid_time], byte 1

    ; 3 puta parsiramo dve cifre
.parse_hours:
    call _parse_2dig_int
    cmp al, 24 
    jl .write_hours
    jmp .fail
.write_hours:
    mov [si], al
    inc si
.parse_minutes:
    cmp byte [di], ':'
    jne .fail
    inc di
    call _parse_2dig_int
    cmp al, 60 
    jl .write_minutes
    jmp .fail
.write_minutes:
    mov [si], al
    inc si
.parse_seconds:
    cmp byte [di], ':'
    jne .fail
    inc di
    call _parse_2dig_int
    cmp al, 60 
    jl .write_seconds
    jmp .fail
.write_seconds:
    mov [si], al
    inc si
    jmp .end
.fail:
    mov [valid_time], byte 0
.end:
    ret

; ==================================================
; Snuzovanje vremena
; ================================================== 

_snooze_time:
    pusha
    mov [cs:valid_time], byte 1
    mov si, time
    mov bh, [si]
    inc si
    mov bl, [si]
    inc si
    mov dl, [si]
    ; BH BL DL
    inc bl
    cmp bl, 60
    jne .end
    xor bl, bl
    inc bh
    ; ako bh postane 24 jbg
.end:
    popa
    ret

; ==================================================
; Parsiranje dvocifrenog inta
; in:
;      di = pocetak inta
; out:
;      al = parsovani int
;      di = iza kraja inta
; ================================================== 

_parse_2dig_int:
    mov al, [di]
    sub al, ASCII_ZERO
    mov bx, 10
    mul bx
    inc di
    add al, [di]
    sub al, ASCII_ZERO
    inc di
    ret


; ==================================================
; Diffovanje vremena
; in:
;      ch = sati sada, cl = min sada, dh = sekunde sada
;      time = sati sada, time+1 = min sada, time+2 = sekunde sada
;      time je sigurno kasnije ili u isto vreme kao ch cl dh
; out:
;      ch = sati diff, cl = min diff, dh = sekunde diff
; ================================================== 

_diff_time:

    mov si, time
    mov bh, [si]
    inc si
    mov bl, [si]
    inc si
    mov dl, [si]
    ; BH BL DL - CH CL DH

    ; SECONDS
    cmp dl, dh
    jge .sub_s
    add dl, 60
    sub bl, 1
.sub_s:
    sub dl, dh
    mov dh, dl
    ; MINUTES
    cmp bl, cl
    jge .sub_m
    add bl, 60
    sub bh, 1
.sub_m:
    sub bl, cl
    mov cl, bl
    ; HOURS
.sub_h:
    sub bh, ch
    mov ch, bh


    ;mov ah, 0
    ;mov al, ch
    ;call _print_int
    ;mov al, cl
    ;call _print_int
    ;mov al, dh
    ;call _print_int
    ;call _newline


    ret



; ==================================================
; Podaci
; ==================================================

segment .data

time: times 3 db 0
time_rem: times 3 db 0
valid_time: db 0
msg_debug: db 'ZEZ', 0