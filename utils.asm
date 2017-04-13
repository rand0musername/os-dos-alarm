; ##################################################
; Pomocne funkcije
; ##################################################

segment .code

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
      mov  ah, 0Eh                      ; ispis BIOS prekidom
      int  10h
      jmp .print_char     
.end:
      popa
      ret    

; ==================================================
; Ispis celog broja na ekran (BIOS)
; in:
;      ax = int koji treba ispisati
; ================================================== 
_print_int:
    pusha
    mov cx, 0           ; brojac cifara
    mov bx, 10          ; delicemo uvek sa 10
.divide:
    mov dx, 0           ; priprema za deljenje
    div bx              ; ax / bx = ah(al)
    push dx             ; ostatak na stack
    inc cx              ; povecanje brojaca cifri
    or ax, ax           ; provera da li ima jos cifara
    jnz .divide
.print:
    pop ax
    add al, ASCII_ZERO  ; zelimo da ispisemo char 0 a ne broj 0
    mov ah, 0Eh
    int 10h             ; ispis BIOS prekidom
    loop .print
.end:
    mov al, ' '         ; razmak na kraju                    
    mov  ah, 0Eh                      
    int  10h
    popa
    ret

; ==================================================
; Ispis novog reda
; ================================================== 
_print_newline:
    pusha
    mov al, 0Dh         ; CR        
    mov  ah, 0Eh             
    int  10h
    mov al, 0Ah         ; LF                
    mov  ah, 0Eh                 
    int  10h
    popa
    ret

; ==================================================
; Parsiranje vremena (TODO: omoguciti alarm koji je sutradan)
; in:
;      di = pocetak vremenskog stringa HH:MM:SS
; out:
;      time, time+1, time+2 = parsovano vreme
;      valid_time = marker koji oznacava da li je parsiranje uspelo
; ================================================== 
_parse_time:
    mov si, time
    mov [valid_time], byte 1            ; pretpostavimo da je parsiranje uspelo
.parse_hours:                           ; parsiramo sate i proveravamo da li su u opsegu [0, 23]
    call _parse_2dig_int
    cmp al, 24 
    jl .write_hours
    jmp .fail
.write_hours:                           ; upisujemo sate u memoriju
    mov [si], al
    inc si
.parse_minutes:                         ; parsiramo minute i proveravamo da li su u opsegu [0, 59]
    cmp byte [di], ':'
    jne .fail
    inc di
    call _parse_2dig_int
    cmp al, 60 
    jl .write_minutes
    jmp .fail
.write_minutes:                         ; upisujemo minute u memoriju
    mov [si], al
    inc si
.parse_seconds:                         ; upisujemo sekunde i proveravamo da li su u opsegu [0, 59]
    cmp byte [di], ':'
    jne .fail
    inc di
    call _parse_2dig_int
    cmp al, 60 
    jl .write_seconds
    jmp .fail
.write_seconds:                         ; upisujemo sekunde u memoriju
    mov [si], al
    inc si
    jmp .end
.fail:
    mov [valid_time], byte 0            ; markiramo neuspeh
.end:
    ret


; ==================================================
; Parsiranje dvocifrenog inta
; in:
;      di = pocetak stringa gde se nalazi broj
; out:
;      al = parsovani int
;      di = prvi karakter iza kraja inta
; ================================================== 
_parse_2dig_int:
    mov al, [di]                        ; uzimamo prvu cifru i mnozimo sa 10
    sub al, ASCII_ZERO
    mov bx, 10
    mul bx
    inc di                              ; dodajemo drugu cifru
    add al, [di]
    sub al, ASCII_ZERO
    inc di                              ; pomeramo pokazivac
    ret

; ==================================================
; Snoozovanje alarma za 60 sekundi
; out:
;      time, time+1, time+2 = povecano vreme
; ================================================== 
_snooze_time:
    pusha
    mov si, time                        ; uzimamo vreme iz memorije
    mov bh, [si]
    inc si
    mov bl, [si]
    inc si
    mov dl, [si]
    inc bl                              ; povecavamo minute za 1
    cmp bl, 60
    jne .write
    xor bl, bl
    inc bh                              ; bh moze da postane 24, WONTFIX
.write:                                 ; upisujemo novo vreme u memoriju
    mov [si], dl
    dec si
    mov [si], bl
    dec si
    mov [si], bh
.end:
    popa
    ret

; ==================================================
; Racunanje razlike dva vremenska momenta, A i B
; in:
;      ch = satiA, cl = minA, dh = sekundeA (time now)
;      time = satiB, time+1 = minB, time+2 = sekundeB (alarm)
;      [time je sigurno kasnije ili u isto vreme kao now]
; out:
;      ch = sati diff, cl = min diff, dh = sekunde diff
; ================================================== 
_diff_time:
    ; ucitavamo vreme iz memorije u BH BL DL
    mov si, time
    mov bh, [si]
    inc si
    mov bl, [si]
    inc si
    mov dl, [si]
    ; racuna se razlika BH BL DL - CH CL DH
    ; oduzimamo sekunde
    cmp dl, dh
    jge .sub_s
    ; potrebna je pozajmica
    add dl, 60
    or bl, bl
    jnz .regular
    ; potrebna je dupla pozajmica
    add bl, 60
    sub bh, 1
.regular:
    sub bl, 1
.sub_s:
    sub dl, dh
    mov dh, dl
    ; oduzimamo minute
    cmp bl, cl
    jge .sub_m
    ; pozajmica
    add bl, 60
    sub bh, 1
.sub_m:
    sub bl, cl
    mov cl, bl
    ; oduzimamo sate
.sub_h:
    sub bh, ch
    mov ch, bh
    ret
