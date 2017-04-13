; ##################################################
; OS 1. domaci: DOS alarm
;   - instaliranje i uklanjanje TSR (2Fh), reentrancy 
; ##################################################

org 100h
segment .code

; ==================================================
; Ulazna tacka za program
; ================================================== 

main:
    call _parse_flags
    int 20h                             ; exit

; ==================================================
; Parsiranje command line flags (CLF)
; Todo: preciznije parsiranje komandi (prolaze -starttttt i 23:50:500)
; ================================================== 
_parse_flags:
    pusha
    cld
    mov cx, 0100h                       ; max duzina pocetne serije razmaka
    mov di, 81h                         ; pocetak CLF u PSP
    mov al, ' '
    repe scasb                          ; pomera se dok ne nadje nesto sto nije razmak
    dec di
    ; proveravamo da li je komanda start
    push di
    mov si, cmd_start
    mov cx, CMD_START_LEN               ; duzina komande start, TODO: strlen
    repe cmpsb                          ; poredi SI i DI i pomera se dok su jednaki
    je .do_start
    ; proveravamo da li je komanda sstoptart
    pop di
    mov si, cmd_stop
    mov cx, CMD_STOP_LEN                ; duzina komande stop, TODO: strlen
    repe cmpsb
    je .do_stop
    ; nepoznata komanda, ispisat error poruke
    mov si, err_command
    call _print
    jmp .end
    ; obrada start komande
.do_start:
    ; treba parsirati vreme, postavljamo fleg validnosti na nula
    mov [valid_time], byte 0
    ; clear razmake jos jedan put
    cld
    mov cx, 0100h 
    mov al, ' '                         
    repe scasb                          
    dec di
    ; parsiramo vreme
    call _parse_time
    mov al, [valid_time]
    or al, al                           ; ako nije valid time skoci na kraj
    je .invalid_time
    call _alarm_start                   ; ako je valid time zovi alarm start
    jmp .end
.invalid_time:
    ; greska: nevalidno vreme
    mov si, err_time
    call _print
    jmp .end
    ; obrada stop komande
.do_stop:
    call _alarm_stop                    ; zovemo podrutinu za alarm stop
    jmp .end
    ; kraj obrade CLF
.end:
    popa
    ret

; ==================================================
; Pokretanje alarma, instalacija TSR i postavljanje pocetnih vrednosti
; ==================================================
_alarm_start:
    pusha
    call _find_tsr_id                   ; trazimo TSR_ID za nas signature 
    cmp al, 1
    je .already_installed               ; TSR vec instaliran
    cmp al, 0
    je .no_free_tsr                     ; nema slobodnog TSR_ID
    cmp al, 2
    je .do_install                      ; mozemo da instaliramo
    ; greska: this should never happen
    mov si, err_unknown
    call _print
    jmp .end
.already_installed:
    ; greska: vec instaliran TSR
    mov si, err_installed
    call _print
    jmp .end
.no_free_tsr:
    ; greska: nema slobodnog TSR_ID
    mov si, err_no_free_tsr
    call _print
    jmp .end
.do_install:
    ; TSR instalacija
    mov [loc_2F_id], ah                 ; cuvamo TSR_ID u memoriju
    ; cuvanje adrese indos flaga - reentrancy
    mov ah, 34h
    int 21h
    mov [indos_off], bx
    mov ax, es
    mov [indos_seg], ax
    ; instalacija svih hendlera
    call _inst_all
    ; aktivacija alarma
    mov [state], byte STATE_ACTIVE
    ; ispis poruke: uspesna instalacija
    mov si, msg_successful_install
    call _print
    ; odlazak u TSR
    mov ah, 31h
    mov dx, 0FFh
    int 21h
    ; kraj podrutine u slucaju greske
.end:
    popa
    ret

; ==================================================
; Zaustavljanje alarma, deinstalacija TSR
; ==================================================
_alarm_stop:
    pusha
    mov si, signature
    call _find_tsr_id                   ; trazimo TSR_ID za nas signature 
    cmp al, 1
    je .do_uninstall                    ; moguca je deinstalacija
.not_installed:
    ; greska: TSR nije ni instaliran
    mov si, err_unins_not_installed
    call _print
    jmp .end
.do_uninstall:
    ; _find_tsr_id nam je dao TSR segment, postavljamo DS na taj segment
    push ds
    push es
    pop ds
    call _uninst_all                    ; brisanje nasih interapt hendlera
    call _clear_vid_mem                 ; ciscenje video memorije
    mov si, msg_successful_uninstall    ; ispis poruke
    call _print
    pop ds
.end:
    popa
    ret

; ==================================================
; Pomocni moduli
; ==================================================
%include "utils.asm"
%include "install.asm"
%include "ints.asm"
%include "graphics.asm"

; ==================================================
; Podaci
; ==================================================
segment .data

; komande i duzine (TODO: moze bez duzina nekako)
cmd_start:                  db  '-start', 0  
cmd_stop:                   db  '-stop', 0     
CMD_START_LEN               equ 6
CMD_STOP_LEN                equ 5

; poruke
msg_successful_install:     db  'Uspesno aktiviran alarm (s = snooze).', 0Dh, 0Ah, 0
msg_successful_uninstall:   db  'Uspesno deaktiviran alarm.', 0Dh, 0Ah, 0
err_command:                db  'Nepoznat command line flag.', 0Dh, 0Ah, 0
err_time:                   db  'Los format vremena, odstupa od [HH:MM:SS].', 0Dh, 0Ah, 0
err_unknown:                db  'Nepoznata greska :(', 0Dh, 0Ah, 0
err_installed:              db  'Greska pri instalaciji: TSR je vec instaliran.', 0Dh, 0Ah, 0
err_no_free_tsr:            db  'Greska pri instalaciji: nema mesta za novi TSR.', 0Dh, 0Ah, 0
err_unins_not_installed:    db  'Greska pri deinstalaciji: TSR nije ni instaliran.', 0Dh, 0Ah, 0
err_unknown_function:       db  'Nepoznata TSR funkcija.', 0Dh, 0Ah, 0

; vreme
time:               times 3 db  0                   ; vreme kada alarm zvoni
valid_time:                 db  0                   ; flag validnosti unetog vremena
SNOOZE_KEY                  equ 159                 ; 159 je keycode za s_UP - snooze dugme

; TSR
signature:                  db  'Alarm TSR :)', 0   ; signature naseg TSR-a
loc_2F_id:                  db  0                   ; TSR_ID

; stanje alarma
state:                      db  0                   ; stanje: {0, 1, 2}
STATE_OVER                  equ 0                   ; alarm je ugasen
STATE_ACTIVE                equ 1                   ; alarm odbrojava
STATE_RINGING               equ 2                   ; alarm zvoni
TICKS_RINGING               equ 100                 ; ukupno otkucaja u toku zvonjenja
ticks_left:                 db  0                   ; otkucaja do kraja trenutnog 

; lokacija indos flaga
indos_seg:                  dw  0
indos_off:                  dw  0
