; ##################################################
; Interapt jutilitiji
; ##################################################

; ==================================================
; Ispis inta na ekran (BIOS) - signature TODO
; out:
;      al = 2 : nije nadjen, ah = neki prazan TSR ID
;      al = 1 : pronadjen, ah = TSR ID gde se nalazi
;      al = 0 : nije nadjen i nema free TSRova
; ================================================== 
; TODO: strlen
_find_tsr_id:
    mov cx, 0FFh                    ; trazimo po ovom id 
    mov dx, 0                       ; FREE MESTO
.id_loop:
    mov ah, cl                       ; moramo da sacuvamo cx
    push cx    
    mov al, 0

    int 2Fh                         ; zovemo MUX interrupt da odgovori

    pop cx
    cmp al, 0                       ; da li nije odgovorio?
    je .no_response
    ; ima response
    push cx
    mov cx, 6
    mov ax, cs
    mov ds, ax
    mov si, signature
    repe cmpsb                      ; 2Fh u DI vraca signature string
    pop cx

    je .found
    loop .id_loop
.no_response:
    mov dl, cl
    loop .id_loop
    jmp .not_found
.found:
    mov al, 1
    mov ah, cl
    ret
.not_found:
    or dl, dl
    jz .no_free
    mov al, 2
    mov ah, dl
    ret
.no_free:
    mov al, 0
    ret

; ==================================================
; Importi
; ==================================================


; ==================================================
; Podaci
; ==================================================

segment .data
DBG: db '>intutil debug<', 0
signature: db 'SigSig', 0
GOTOVO: db 'gotovo\n', 0
AGOTOVO: db 'FOUND\n', 0