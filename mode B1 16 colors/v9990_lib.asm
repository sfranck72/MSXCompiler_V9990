; ==============================================================================
; LIBRAIRIE V9990 POUR MSXCOMPILER
; Auteur : Gemini & POLAK
; ==============================================================================


; --- ADRESSES FIXES ---
RAM_EXCHANGE_DATA   EQU $C000   ; Pour les variables simples
RAM_PALETTE         EQU $C010   ; L'adresse fixe de notre tableau de couleurs

; --- PORTS ---
PORT_VRAM           EQU $60      ; Port Données VRAM       
PORT_PALETTE        EQU $61      ; Port Données Palette 
PORT_COMMAND        EQU $62      
PORT_REG_DATA       EQU $63      ; Port Données Registre
PORT_REG_SELECT     EQU $64      ; Port Sélection Registre
PORT_STATUS         EQU $65
PORT_INTER_FLAG     EQU $66     
PORT_SYS_CTRL       EQU $67      ; Port Contrôle Système        

; --- CONSTANTES CONFIGURATION ---
MODE_ENABLE         EQU 128         
MODE_B1_REG7        EQU 0           

; ------------------------------------------------------------------------------
; V9_DETECT
; Vérifie la présence en écrivant $A5 à l'adresse 0 et en relisant via Reg 3
; ------------------------------------------------------------------------------
V9_DETECT:
    ; Fixer l'adresse d'écriture à 0
    xor a
    out (PORT_REG_SELECT), a
    out (PORT_REG_DATA), a       ; Write Addr Low
    out (PORT_REG_DATA), a       ; Write Addr Mid
    out (PORT_REG_DATA), a       ; Write Addr High
    
    ; Écrire la valeur test
    ld a, $A5
    out (PORT_VRAM), a
    
    ; Fixer l'adresse de lecture à 0 (Registre 3 = Read Address)
    ld a, 3
    out (PORT_REG_SELECT), a
    xor a
    out (PORT_REG_DATA), a       ; Read Addr Low
    out (PORT_REG_DATA), a       ; Read Addr Mid
    out (PORT_REG_DATA), a       ; Read Addr High
    
    ; Lire le port VRAM et comparer
    in a, (PORT_VRAM)
    cp $A5
    jp z, V9_DETECT_OK
    
    ; Échec : renvoyer 0
    xor a
    ld (RAM_EXCHANGE_DATA), a
    ret

V9_DETECT_OK:
    ld a, 255
    ld (RAM_EXCHANGE_DATA), a
    ret
   
; ==============================================================================
; V9_RESET
; ==============================================================================
V9_RESET:
    ld a, 2                     
    out (PORT_SYS_CTRL), a
    xor a
    out (PORT_SYS_CTRL), a       

    ld a, 8             
    out (PORT_REG_SELECT), a
    xor a          
    out (PORT_REG_DATA), a
    ret

; ==============================================================================
; V9_SETMODE_16 -> 16 couleurs 256 x 212
; ==============================================================================
V9_SETMODE_16:
    ld a, 6
    out (PORT_REG_SELECT), a
    ld a, 129           ; Mode B1 16 couleurs
    out (PORT_REG_DATA), a

    ld a, 7             ; Reg 7 = 0
    out (PORT_REG_SELECT), a
    xor a               
    out (PORT_REG_DATA), a
    
    ; ld a, 13            ; Reg 13 = Palette BANK 0
    ; out (PORT_REG_SELECT), a
    ; xor a
    ; out (PORT_REG_DATA), a
    ; ret

    ld a, 8             ; Reg 8 = display VRAM + 512 ko VRAM      
    out (PORT_REG_SELECT), a
    ld a, 130
    out (PORT_REG_DATA), a
    ret

; ==============================================================================
; V9_SETMODE_64 -> 64 couleurs 256 x 212
; ==============================================================================
V9_SETMODE_64:
    ld a, 6
    out (PORT_REG_SELECT), a
    ld a, 130           ; Mode B1 64 couleurs
    out (PORT_REG_DATA), a
    
    ld a, 7             ; Reg 7 = 0
    out (PORT_REG_SELECT), a
    xor a               
    out (PORT_REG_DATA), a
    
    ; ld a, 13            ; Reg 13 = Palette BANK 0
    ; out (PORT_REG_SELECT), a
    ; xor a
    ; out (PORT_REG_DATA), a
    
    ld a, 8             ; Reg 8 = display VRAM + 512 ko VRAM      
    out (PORT_REG_SELECT), a
    ld a, 130
    out (PORT_REG_DATA), a
    ret

; ==============================================================================
; V9_INIT_PALETTE_16
; Envoie les 48 octets situés en $C010 vers le VDP -> 16 couleurs
; ==============================================================================
V9_INIT_PALETTE_16:
    ; 1. Forcer la banque de palette 0 (R#13)
    ld a, 13
    out (PORT_REG_SELECT), a
    xor a
    out (PORT_REG_DATA), a       ; R#13 = 0 (Banque 0)

    ; 2. Pointer sur l'index de couleur 0 (R#14)
    ld a, 14
    out (PORT_REG_SELECT), a
    xor a
    out (PORT_REG_DATA), a       ; R#14 = 0 (Index 0)

    ; 3. Transfert des données (RAM -> Port $61)
    ld hl, LabelColors          ; dans le fichier colors.asm
    ld b, 48                    ; 16 couleurs * 3 octets
    ld c, PORT_PALETTE
    otir
    ret

; ==============================================================================
; V9_INIT_PALETTE
; Envoie les 64 octets situés en $C010 vers le VDP -> 64 couleurs
; ==============================================================================
V9_INIT_PALETTE_64:
    ; 1. Forcer la banque de palette 0 (R#13)
    ld a, 13
    out (PORT_REG_SELECT), a
    xor a
    out (PORT_REG_DATA), a       ; R#13 = 0 (Banque 0)

    ; 2. Pointer sur l'index de couleur 0 (R#14)
    ld a, 14
    out (PORT_REG_SELECT), a
    xor a
    out (PORT_REG_DATA), a       ; R#14 = 0 (Index 0)

    ; 3. Transfert des données (RAM -> Port $61)
    ld hl, LabelColors          ; dans le fichier colors.asm
    ld b, 192                   ; 64 couleurs * 3 octets
    ld c, PORT_PALETTE
    otir
    ret



; ==============================================================================
; V9_SET_BACKDROP
; Lit l'index de couleur en $C000
; ==============================================================================
V9_SET_BACKDROP:
    ld a, (RAM_EXCHANGE_DATA)       ; Lit la valeur posee par le POKE du BASIC
    push af
    ld a, 15                        ; Registre Back Drop
    out (PORT_REG_SELECT), a
    pop af
    out (PORT_REG_DATA), a
    ret

; ==============================================================================
; V9_SCREEN_ENABLE
; Active l'affichage du VDP V9990
; ==============================================================================
V9_SCREEN_ENABLE:
    ld a, 72                    ; REG 8 + LECT 64 = 72
    out (PORT_REG_SELECT), a
    in a, (PORT_REG_DATA)
    OR MODE_ENABLE              ; display vram V9990
    out (PORT_REG_DATA), a
    ret

; ------------------------------------------------------------------------------
; V9_SET_VRAM_WRITE_ADDR
; Configure l'adresse d'écriture sur 3 octets (24 bits)
; Lit $C000 (L), $C001 (M), $C002 (H)
; ------------------------------------------------------------------------------
V9_SET_VRAM_WRITE_ADDR:
    xor a
    out (PORT_REG_SELECT), a     ; Registre 0 (Write Address Low)
    
    ld a, (RAM_EXCHANGE_DATA)       ; Valeur Low
    out (PORT_REG_DATA), a
    
    ld a, (RAM_EXCHANGE_DATA+1)     ; Valeur Mid
    out (PORT_REG_DATA), a
    
    ld a, (RAM_EXCHANGE_DATA+2)     ; Valeur High
    out (PORT_REG_DATA), a
    ret


; ------------------------------------------------------------------------------
; V9_PREPARE_TRANSFER
; Prépare le V9990 à recevoir des données en VRAM à l'adresse 0
; ------------------------------------------------------------------------------
V9_PREPARE_TRANSFER:
    xor a
    out (PORT_REG_SELECT), a     ; Registre 0 (Write Address Low)
    out (PORT_REG_DATA), a
    out (PORT_REG_DATA), a
    out (PORT_REG_DATA), a
    ret

; ------------------------------------------------------------------------------
; V9_TRANSFER_HL_BC (Version Rapide)
; HL = Source, BC = Taille
; ------------------------------------------------------------------------------
; HL = Source ($C000), BC = Taille ($C002)
V9_TRANSFER_HL_BC:
    ld hl, ($C000)      ; Récupère l'adresse source stockée en RAM
    ld bc, ($C002)      ; Récupère la taille stockée en RAM
    ld a, b
    or c
    ret z
_v9_loop:               ; Label unique pour éviter les conflits
    ld a, (hl)
    out (PORT_VRAM), a
    inc hl
    dec bc
    ld a, b
    or c
    jr nz, _v9_loop
    ret
