; ##################################################
; Interapt hendleri
; ##################################################

segment .code

; ==================================================
; Interapt hendler za 2F - MUX
; out (f0):
;           di = signature
;           al = FFh
;           es = TSR segment
; TODO: mozda treba ceo int 1Ch preseliti ovde u .f1?
;       nije najjasnije kako se koristi 2F u kombinaciji sa interapt hendlerima
;       ovako kako je sada odradjeno ne postoji neka jaka veza 2F Entry <=> 1C handler
; ==================================================
irt_2F:
    ; provera da li je id tacan
    cmp ah, [cs:loc_2F_id]
    jne .continue
    ; odabir funkcije
    cmp al, 0
    je .f0
    mov si, err_unknown_function
    call _print
    jmp .continue
.f0:
    ; funkcija nula: "ping" - vracamo FFh i signature
    mov al, 0FFh
    mov di, signature
    mov dx, cs
    mov es, dx                          ; saljemo i segment u kom je TSR kroz es
    iret
    ; nastavak po 2F lancu, pogresan handler
.continue:
    push word [cs:loc_2F_seg]
    push word [cs:loc_2F_off]
    retf

; ==================================================
; Interapt hendler za 1C - tajmer
; ==================================================
irt_1C:
    pusha
    ; popravka za ds da bi uzimali podatke iz TSR segmenta
    mov ax, cs
    mov ds, ax
    ; da li je alarm vec gotov
    cmp [cs:state], byte STATE_OVER
    je .end
    ; da li alarm zvoni
    cmp [cs:state], byte STATE_RINGING
    je .ringing
.active:
    ; reentrancy, provera indos flaga
    mov ax, [cs:indos_seg]
    mov es, ax
    mov bx, [cs:indos_off]
    mov al, byte [es:bx]
    or al, al
    jnz .end 
    ; ne koriste se interapti, mozemo da nastavimo
    mov ah, 2Ch                         ; uzimamo sistemsko vreme
    int 21h
    ; ch = sati sada, cl = min sada, dh = sekunde sada
    call _diff_time                     ; racunamo razliku izmedju alarma i sada
    ; ch = sati diff, cl = min diff, dh = sekunde diff
    ; provera da li je vreme da alarm pocne da zvoni
    or ch, ch
    jnz .draw
    or cl, cl
    jnz .draw
    or dh, dh
    jnz .draw
    ; draw da zvoni od narednog ticka
    mov [cs:state], byte STATE_RINGING
    mov [cs:ticks_left], byte TICKS_RINGING
.draw:
    ; crtamo odbrojavanje 
    call _clear_vid_mem
    call _print_time
    jmp .end
.ringing:
    ; alarm zvoni, smanjimo broj tickova do kraja
    mov al, [cs:ticks_left]
    or al, al
    jz .set_over
    dec al
    mov [cs:ticks_left], byte al
    ; crtamo zvonjenje
    call _clear_vid_mem
    call _print_ring
    jmp .end
.set_over:
    ; kraj zvonjenja, menjamo stanje 
    mov [cs:state], byte STATE_OVER
    call _clear_vid_mem
    call _alarm_stop                    ; deinstaliramo alarm
    jmp .end
.end:
    popa
    iret

; ==================================================
; Interapt hendler za 09 - tastatura (snooze)
; ==================================================
irt_09:
    pusha
    mov ax, cs
    mov ds, ax 
    mov ax, 0            
    in al, KBD                          ; da li je pritistnuto snooze dugme
    cmp al, SNOOZE_KEY
    jne .continue
    cmp [cs:state], byte STATE_RINGING  ; da li alarm zvoni
    jne .continue
.snooze:
    mov [cs:state], byte STATE_ACTIVE   ; stanje postaje aktivno
    call _snooze_time                   ; dodajemo minut na vreme
.continue:
    ; predaje se kontrola starom 09 interaptu
    popa
    push word [cs:loc_09_seg]
    push word [cs:loc_09_off]
    retf

; ==================================================
; Pomocna sabrutina koja trazi TSR sa zadatim signature
; TODO: parametrizovati signature
; out:
;      al = 2 : nije nadjen, ah = neki prazan TSR_ID
;      al = 1 : pronadjen, ah = TSR_ID gde se nalazi
;      al = 0 : nije nadjen i nema slobodnih TSR slotova
; ================================================== 
; TODO: strlen
_find_tsr_id:
    mov cx, 0FFh                    ; trazimo po ovom id unazad
    mov dx, 0                       ; u dx se cuva slobodno mesto
.id_loop:
    mov ah, cl                       
    push cx                         ; moramo da sacuvamo cx
    mov al, 0
    int 2Fh                         ; trazimo odgovor od MUX interapta
    pop cx
    cmp al, 0                       ; da li smo dobili odgovor
    je .no_response
    ; ima odgovora, provera potpisa
    push cx
    mov cx, 6
    mov ax, cs
    mov ds, ax
    mov si, signature
    repe cmpsb                      ; poredi se signature sa DI (signature koji je vratio 2Fh)
    pop cx
    ; ako su stringovi jednaki nasli smo zeljeni TSR
    je .found
    loop .id_loop
.no_response:
    ; nema odgovora, trazimo dalje
    mov dl, cl
    loop .id_loop
    jmp .not_found
.found:
    ; nadjen TSR
    mov al, 1
    mov ah, cl
    ret
.not_found:
    ; nema TSR
    or dl, dl
    jz .no_free
    ; ima mesta
    mov al, 2
    mov ah, dl
    ret
.no_free:
    ; nema mesta
    mov al, 0
    ret

; ==================================================
; Podaci
; ==================================================
segment .data

; lokacije starih interapt hendlera
loc_1C_seg: dw 0
loc_1C_off: dw 0
loc_09_seg: dw 0
loc_09_off: dw 0
loc_2F_seg: dw 0
loc_2F_off: dw 0

; lokacija tastature kao ulaznog uredjaja
KBD         equ 060h 