; ##################################################
; Glavni deo programa
; ##################################################

org 100h
segment .code

; ==================================================
; Main
; ================================================== 

main:
    call _parse_flags
    int 20h

; ==================================================
; Parsiranje komandne linije
; ================================================== 

_parse_flags:
    pusha
    cld
    mov cx, 0100h                       ; max duzina razmaka
    mov di, 81h                         ; pocetak komande linije u PSP
    mov al, ' '
    repe scasb                          ; pomera se dok ne nadje nesto sto nije razmak
    dec di

    ; proveravamo start
    push di
    mov si, cmd_start
    mov cx, CMD_START_LEN               ; duzina komande
    repe cmpsb                          ; poredi SI i DI i pomera se dok su jednaki
    je .do_start

    ; proveravamo stop
    pop di
    mov si, cmd_stop
    mov cx, CMD_STOP_LEN                ; duzina komande
    repe cmpsb                          ; poredi SI i DI i pomera se dok su jednaki
    je .do_stop

    ; error, ispisati error poruku
    mov si, err_command
    call _print
    jmp .end

    ; obrada start komande
.do_start:
    ; valid time reset 
    mov [valid_time], byte 0
    ; clear razmake opet
    cld
    mov cx, 0100h 
    mov al, ' '                         ; opet preskocimo razmake
    repe scasb                          ; pomera se dok ne nadje nesto sto nije razmak
    dec di
    ; parsiramo vreme
    call _parse_time
    mov al, [valid_time]
    or al, al                           ; ako nije valid time skoci na kraj
    je .invalid_time
    call _alarm_start                   ; ako je valid time zovi alarm start
    jmp .end
.invalid_time:
    mov si, err_time
    call _print
    jmp .end

    ; obrada stop komande
.do_stop:
    call _alarm_stop
    jmp .end

    ; kraj podrutine
.end:
    popa
    ret


; ==================================================
; Pokretanje alarma
; ==================================================
_alarm_start:
    pusha
    call _find_tsr_id

    mov si, signature
    call _print

    mov bx, ax
    mov ax, 0
    mov al, bl
    call _print_int
    mov si, dbg
    call _print
    mov ax, 0
    mov al, bh
    call _print_int
    mov ax, bx

    cmp al, 1
    je .already_installed
    cmp al, 0
    je .no_free_tsr
    cmp al, 2
    je .do_install
    mov si, err_unknown
    call _print
    jmp .end
.already_installed:
    mov si, err_installed
    call _print
    jmp .end
.no_free_tsr:
    mov si, err_no_free_tsr
    call _print
    jmp .end
.do_install:
    ; sacuvaj 2F id
    mov [loc_2F_id], ah
    ; nadji adresu indos flaga
    mov ah, 34h
    int 21h
    mov [indos_off], bx
    mov ax, es
    mov [indos_seg], ax
    ; instaliraj sve hendlere
    call _inst_all
    ; aktiviraj alarm
    mov [state], byte STATE_ACTIVE

    mov si, msg_tsr
    call _print

    ; go FULL TSR
    mov ah, 31h
    mov dx, 0FFh
    int 21h
    ; end
.end:
    popa
    ret

; ==================================================
; Zaustavljanje alarma
; ==================================================
_alarm_stop:
    pusha
    mov si, signature
    call _find_tsr_id
    cmp al, 1
    je .do_uninstall
.not_installed:
    mov si, err_unins_not_installed
    call _print
    jmp .end
.do_uninstall:
    push ds
    push es
    pop ds
    call _uninst_all ; garantujem ti es koji valja
    call _clear_vid_mem
    pop ds
.end:
    popa
    ret

; ==================================================
; Importi
; ==================================================

%include "ints.asm"
; TODO utils je includovan negde dole, skontati 
; nesto na foru #ifndef

; ==================================================
; Podaci
; ==================================================
segment .data

cmd_start: db '-start', 0
CMD_START_LEN equ 6
cmd_stop: db '-stop', 0
CMD_STOP_LEN equ 5
msg_debug1: db 'DBG1', 0
msg_debug2: db 'DBG2', 0
dbg: db ' ', 0


err_command: db 'Pogresna komanda.', 0
err_time: db 'Lose formatirano vreme.', 0
err_unknown: db 'Nepoznata greska.', 0
err_installed: db 'Greska pri instalaciji: TSR vec instaliran.', 0
err_no_free_tsr: db 'Greska pri instalaciji: nema mesta za novi TSR.', 0
err_unins_not_installed: db 'Greska pri deinstalaciji: TSR nije prisutan.', 0

msg_tsr: db 'Going full TSR.', 0