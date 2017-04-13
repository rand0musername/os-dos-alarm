; ##################################################
; Instaliranje i deinstaliranje interapt rutina
; TODO: dosta ponovljenog koda, moze da se skrati 
;       generickom rutinom koja instalira
; ##################################################

segment .code

; ==================================================
; Instalacija svih neophodnih interapt rutina (2F, 1C, 09)
; ================================================== 
_inst_all:
    push es
    push si
    call _inst_2F                       ; MUX
    call _inst_1C                       ; timer
    call _inst_09                       ; keyboard
    pop si
    pop es
    ret

; ==================================================
; Deinstalacija svih neophodnih interapt rutina (2F, 1C, 09)
; in:
;      es - segment gde se nalazi TSR
; ================================================== 
_uninst_all:
    push es
    push si
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
; Instalacija i brisanje 2F handlera - MUX
; ================================================== 
_inst_2F:
    cli
    xor ax, ax
    mov es, ax                          ; ES = 0
    ; cuvanje stare rutine
    mov bx, [es:2Fh*4+2]
    mov [loc_2F_seg], bx
    mov bx, [es:2Fh*4]
    mov [loc_2F_off], bx
    ; instalacija nase rutine
    mov ax, cs
    mov [es:2Fh*4+2], ax
    mov bx, irt_2F
    mov [es:2Fh*4], bx
    sti
    ret

; TODO: ovo nije najpravilnije, treba free memorije
; kako bi se oslobodio TSR - ovako i dalje zauzima memoriju?
_uninst_2F:
    ; vracanje stare rutine
    cli
    xor ax, ax
    mov es, ax
    mov ax, [loc_2F_seg]
    mov [es:2Fh*4+2], ax
    mov dx, [loc_2F_off]
    mov [es:2Fh*4], dx
    sti
    ret

; ==================================================
; Instalacija i brisanje 2F handlera - timer tick
; ================================================== 
_inst_1C:
    cli
    xor ax, ax
    mov es, ax                          ; ES = 0
    ; cuvanje stare rutine
    mov bx, [es:1Ch*4+2]
    mov [loc_1C_seg], bx
    mov bx, [es:1Ch*4]
    mov [loc_1C_off], bx
    ; instalacija nase rutine
    mov ax, cs
    mov [es:1Ch*4+2], ax
    mov bx, irt_1C
    mov [es:1Ch*4], bx
    sti
    ret

_uninst_1C:
    ; vracanje stare rutine
    cli
    xor ax, ax
    mov es, ax
    mov ax, [loc_1C_seg]
    mov [es:1Ch*4+2], ax
    mov dx, [loc_1C_off]
    mov [es:1Ch*4], dx
    sti
    ret

; ==================================================
; Instalacija i brisanje 09 handlera - keyboard
; ================================================== 
_inst_09:
    cli
    xor ax, ax
    mov es, ax                          ; ES = 0
    ; cuvanje stare rutine
    mov bx, [es:09h*4+2]
    mov [loc_09_seg], bx
    mov bx, [es:09h*4]
    mov [loc_09_off], bx
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
    mov ax, [loc_09_seg]
    mov [es:09h*4+2], ax
    mov dx, [loc_09_off]
    mov [es:09h*4], dx
    sti
    ret
