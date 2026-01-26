; ==============================================================================
; V9990 LIBRARY FOR MSXCOMPILER
; Author: Gemini & POLAK
; ==============================================================================


; --- FIXED ADDRESSES ---
RAM_EXCHANGE_DATA   EQU $C000   ; For simple variables
RAM_PALETTE         EQU $C010   ; Fixed address for our color table

; --- PORTS ---
PORT_VRAM           EQU $60      ; VRAM Data Port       
PORT_PALETTE        EQU $61      ; Palette Data Port 
PORT_COMMAND        EQU $62      
PORT_REG_DATA       EQU $63      ; Register Data Port
PORT_REG_SELECT     EQU $64      ; Register Select Port
PORT_STATUS         EQU $65
PORT_INTER_FLAG     EQU $66     
PORT_SYS_CTRL       EQU $67      ; System Control Port        

; --- CONFIGURATION CONSTANTS ---
MODE_ENABLE         EQU 128         
MODE_B1_REG7        EQU 0           

; ------------------------------------------------------------------------------
; V9_DETECT
; Checks for presence by writing $A5 to address 0 and reading back via Reg 3
; ------------------------------------------------------------------------------
V9_DETECT:
    ; Set write address to 0
    xor a
    out (PORT_REG_SELECT), a
    out (PORT_REG_DATA), a       ; Write Addr Low
    out (PORT_REG_DATA), a       ; Write Addr Mid
    out (PORT_REG_DATA), a       ; Write Addr High
    
    ; Write test value
    ld a, $A5
    out (PORT_VRAM), a
    
    ; Set read address to 0 (Register 3 = Read Address)
    ld a, 3
    out (PORT_REG_SELECT), a
    xor a
    out (PORT_REG_DATA), a       ; Read Addr Low
    out (PORT_REG_DATA), a       ; Read Addr Mid
    out (PORT_REG_DATA), a       ; Read Addr High
    
    ; Read VRAM port and compare
    in a, (PORT_VRAM)
    cp $A5
    jp z, V9_DETECT_OK
    
    ; Failure: return 0
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
; V9_SETMODE_16 -> 16 colors 256 x 212
; ==============================================================================
V9_SETMODE_16:
    ld a, 6
    out (PORT_REG_SELECT), a
    ld a, 129           ; Mode B1 16 colors
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

    ld a, 8             ; Reg 8 = display VRAM + 512 KB VRAM      
    out (PORT_REG_SELECT), a
    ld a, 130
    out (PORT_REG_DATA), a
    ret

; ==============================================================================
; V9_SETMODE_64 -> 64 colors 256 x 212
; ==============================================================================
V9_SETMODE_64:
    ld a, 6
    out (PORT_REG_SELECT), a
    ld a, 130           ; Mode B1 64 colors
    out (PORT_REG_DATA), a
    
    ld a, 7             ; Reg 7 = 0
    out (PORT_REG_SELECT), a
    xor a               
    out (PORT_REG_DATA), a
    
    ; ld a, 13            ; Reg 13 = Palette BANK 0
    ; out (PORT_REG_SELECT), a
    ; xor a
    ; out (PORT_REG_DATA), a
    
    ld a, 8             ; Reg 8 = display VRAM + 512 KB VRAM      
    out (PORT_REG_SELECT), a
    ld a, 130
    out (PORT_REG_DATA), a
    ret

; ==============================================================================
; V9_INIT_PALETTE_16
; Sends the 48 bytes located at $C010 to the VDP -> 16 colors
; ==============================================================================
V9_INIT_PALETTE_16:
    ; 1. Force palette bank 0 (R#13)
    ld a, 13
    out (PORT_REG_SELECT), a
    xor a
    out (PORT_REG_DATA), a       ; R#13 = 0 (Bank 0)

    ; 2. Point to color index 0 (R#14)
    ld a, 14
    out (PORT_REG_SELECT), a
    xor a
    out (PORT_REG_DATA), a       ; R#14 = 0 (Index 0)

    ; 3. Data transfer (RAM -> Port $61)
    ld hl, LabelColors          ; in the colors.asm file
    ld b, 48                    ; 16 colors * 3 bytes
    ld c, PORT_PALETTE
    otir
    ret

; ==============================================================================
; V9_INIT_PALETTE_64
; Sends the 192 bytes located at $C010 to the VDP -> 64 colors
; ==============================================================================
V9_INIT_PALETTE_64:
    ; 1. Force palette bank 0 (R#13)
    ld a, 13
    out (PORT_REG_SELECT), a
    xor a
    out (PORT_REG_DATA), a       ; R#13 = 0 (Bank 0)

    ; 2. Point to color index 0 (R#14)
    ld a, 14
    out (PORT_REG_SELECT), a
    xor a
    out (PORT_REG_DATA), a       ; R#14 = 0 (Index 0)

    ; 3. Data transfer (RAM -> Port $61)
    ld hl, LabelColors          ; in the colors.asm file
    ld b, 192                   ; 64 colors * 3 bytes
    ld c, PORT_PALETTE
    otir
    ret



; ==============================================================================
; V9_SET_BACKDROP
; Reads the color index from $C000
; ==============================================================================
V9_SET_BACKDROP:
    ld a, (RAM_EXCHANGE_DATA)       ; Reads value set by BASIC POKE
    push af
    ld a, 15                        ; Backdrop Register
    out (PORT_REG_SELECT), a
    pop af
    out (PORT_REG_DATA), a
    ret

; ==============================================================================
; V9_SCREEN_ENABLE
; Enables V9990 VDP display
; ==============================================================================
V9_SCREEN_ENABLE:
    ld a, 72                    ; REG 8 + READ 64 = 72
    out (PORT_REG_SELECT), a
    in a, (PORT_REG_DATA)
    OR MODE_ENABLE              ; display V9990 VRAM
    out (PORT_REG_DATA), a
    ret

; ------------------------------------------------------------------------------
; V9_SET_VRAM_WRITE_ADDR
; Configures the write address using 3 bytes (24 bits)
; Reads $C000 (L), $C001 (M), $C002 (H)
; ------------------------------------------------------------------------------
V9_SET_VRAM_WRITE_ADDR:
    xor a
    out (PORT_REG_SELECT), a     ; Register 0 (Write Address Low)
    
    ld a, (RAM_EXCHANGE_DATA)       ; Low Value
    out (PORT_REG_DATA), a
    
    ld a, (RAM_EXCHANGE_DATA+1)     ; Mid Value
    out (PORT_REG_DATA), a
    
    ld a, (RAM_EXCHANGE_DATA+2)     ; High Value
    out (PORT_REG_DATA), a
    ret


; ------------------------------------------------------------------------------
; V9_PREPARE_TRANSFER
; Prepares V9990 to receive data in VRAM at address 0
; ------------------------------------------------------------------------------
V9_PREPARE_TRANSFER:
    xor a
    out (PORT_REG_SELECT), a     ; Register 0 (Write Address Low)
    out (PORT_REG_DATA), a
    out (PORT_REG_DATA), a
    out (PORT_REG_DATA), a
    ret

; ------------------------------------------------------------------------------
; V9_TRANSFER_HL_BC (Fast Version)
; HL = Source, BC = Size
; ------------------------------------------------------------------------------
; HL = Source ($C000), BC = Size ($C002)
V9_TRANSFER_HL_BC:
    ld hl, ($C000)      ; Retrieves source address stored in RAM
    ld bc, ($C002)      ; Retrieves size stored in RAM
    ld a, b
    or c
    ret z
_v9_loop:               ; Unique label to avoid conflicts
    ld a, (hl)
    out (PORT_VRAM), a
    inc hl
    dec bc
    ld a, b
    or c
    jr nz, _v9_loop
    ret