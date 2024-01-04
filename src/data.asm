; Datamääritelmät 8 x 8 LED
.ifndef SRAM_DATA
.equ SRAM_DATA = 0

.equ KENNOJA = 4
.equ RIVEJA_KENNOSSA = 8
.equ RIVEJA = 36

; Pikselin koordinaattimääritelmät
; Rivi / 8   |  Sarake / 32    |
; R2 R1 R0   | C4 C3 C2 C1 C0  |
; eli automaattisesti:
; Rivi / 8   | Kenno/4  | Sarake kennossa |
; R2 R1 R0   | K1 K0   | C2 C1 C0        |

; Oikoteinä:
; Kennojen numeroinnit
.equ PIX_KENNO0  = 0<<3
.equ PIX_KENNO1  = 1<<3
.equ PIX_KENNO2  = 2<<3
.equ PIX_KENNO3  = 3<<3
; Bittien (kennon sisäisten sarakkeiden) numerointi
.equ PIX_SARAKE0 = 0<<0
.equ PIX_SARAKE1 = 1<<0
.equ PIX_SARAKE2 = 2<<0
.equ PIX_SARAKE3 = 3<<0
.equ PIX_SARAKE4 = 4<<0
.equ PIX_SARAKE5 = 5<<0
.equ PIX_SARAKE6 = 6<<0
.equ PIX_SARAKE7 = 7<<0
; Sarakkeiden numeroinnit
.equ PIX_RIVI0   = 0<<5
.equ PIX_RIVI1   = 1<<5
.equ PIX_RIVI2   = 2<<5
.equ PIX_RIVI3   = 3<<5
.equ PIX_RIVI4   = 4<<5
.equ PIX_RIVI5   = 5<<5
.equ PIX_RIVI6   = 6<<5
.equ PIX_RIVI7   = 7<<5


.dseg
.org SRAM_START
DAT_KENNO3:  .db 0xFF, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0xFF
DAT_KENNO2:  .db 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF
DAT_KENNO1:  .db 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF
DAT_KENNO0:  .db 0xFF, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0xFF
DAT_MATO:    .byte 180 ; maksimipituus 180 pikseliä (6 riviä, sarakkeita 2x8 + 2x7)


.cseg
; Alusta kennojen datat
sram_alusta:
    LDI REG_MUUT1,0xFF
    LDI REG_MUUT2,0x80
    ; Kenno 1 (ylin)
    STS DAT_KENNO3,   REG_MUUT1
    STS DAT_KENNO3+1, REG_MUUT2
    STS DAT_KENNO3+2, REG_MUUT2
    STS DAT_KENNO3+3, REG_MUUT2
    STS DAT_KENNO3+4, REG_MUUT2
    STS DAT_KENNO3+5, REG_MUUT2
    STS DAT_KENNO3+6, REG_MUUT2
    STS DAT_KENNO3+7, REG_MUUT1
    ; Kenno 2
    LDI REG_MUUT2,0x00
    STS DAT_KENNO2,   REG_MUUT1
    STS DAT_KENNO2+1, REG_MUUT2
    STS DAT_KENNO2+2, REG_MUUT2
    STS DAT_KENNO2+3, REG_MUUT2
    STS DAT_KENNO2+4, REG_MUUT2
    STS DAT_KENNO2+5, REG_MUUT2
    STS DAT_KENNO2+6, REG_MUUT2
    STS DAT_KENNO2+7, REG_MUUT1
    ; Kenno 3
    STS DAT_KENNO1,   REG_MUUT1
    STS DAT_KENNO1+1, REG_MUUT2
    STS DAT_KENNO1+2, REG_MUUT2
    STS DAT_KENNO1+3, REG_MUUT2
    STS DAT_KENNO1+4, REG_MUUT2
    STS DAT_KENNO1+5, REG_MUUT2
    STS DAT_KENNO1+6, REG_MUUT2
    STS DAT_KENNO1+7, REG_MUUT1
    ; Kenno 4 (alin)
    LDI REG_MUUT2,0x01
    STS DAT_KENNO0,   REG_MUUT1
    STS DAT_KENNO0+1, REG_MUUT2
    STS DAT_KENNO0+2, REG_MUUT2
    STS DAT_KENNO0+3, REG_MUUT2
    STS DAT_KENNO0+4, REG_MUUT2
    STS DAT_KENNO0+5, REG_MUUT2
    STS DAT_KENNO0+6, REG_MUUT2
    STS DAT_KENNO0+7, REG_MUUT1
    RET


; Hae pikselin REG_PISTE muistiosoite
; ja aseta se REG_OSOITE_L/H arvoksi
sram_pikselin_osoite:
    LDI XL,LOW(DAT_KENNO3)
    LDI XH,HIGH(DAT_KENNO3)
    MOV REG_MUUT1,REG_PISTE                 ; Kennon paikka kahdesta keskimmäisestä
    CBR REG_MUUT1,0xE7
    LDI REG_LOOP1,PIX_KENNO3
    LDI REG_LOOP2,PIX_KENNO1
_loop_sram_pikselin_osoite_kenno:
    CP REG_LOOP1,REG_MUUT1
    BREQ _loop_sram_pikselin_osoite_kenno_end
    SUB REG_LOOP1,REG_LOOP2
    ADIW XH:XL,RIVEJA_KENNOSSA
    RJMP _loop_sram_pikselin_osoite_kenno
_loop_sram_pikselin_osoite_kenno_end:
    MOV REG_MUUT1,REG_PISTE                 ; Rivin paikka kolmesta ylimmästä bitistä
    CBR REG_MUUT1,0x1F
    LDI REG_LOOP1,PIX_RIVI0
    LDI REG_LOOP2,PIX_RIVI1
_loop_sram_pikselin_osoite_rivi:
    CP REG_LOOP1,REG_MUUT1
    BREQ _loop_sram_pikselin_osoite_rivi_end
    ADD REG_LOOP1,REG_LOOP2
    ADIW XH:XL,1
    RJMP _loop_sram_pikselin_osoite_rivi
_loop_sram_pikselin_osoite_rivi_end:
    RET
    
    


; Vaihda pikselin arvo kennosta
; Pisteen tiedot rekisterissä REG_PISTE
sram_vaihda_pikseli:
    PUSH XL
    PUSH XH
    RCALL sram_pikselin_osoite              ; Hae pikselin muistiosoite
    MOV REG_MUUT1,REG_PISTE                 ; Sarakkeen paikka kolmesta alimmasta bitistä
    CBR REG_MUUT1,0xF8
    LDI REG_LOOP1,PIX_SARAKE0
    LDI REG_LOOP2,PIX_SARAKE1
    LDI REG_MUUT2,0x01
_loop_sram_vaihda_pikseli_sarake:
    CP REG_LOOP1,REG_MUUT1
    BREQ _loop_sram_vaihda_pikseli_sarake_end
    ADD REG_LOOP1,REG_LOOP2
    LSL REG_MUUT2
    RJMP _loop_sram_vaihda_pikseli_sarake
_loop_sram_vaihda_pikseli_sarake_end:
    LD REG_MUUT1,X
    EOR REG_MUUT1,REG_MUUT2
    ST X,REG_MUUT1
    POP XH
    POP XL
    RET


; Tarkista onko kysytty pikseli päällä.
; Kysyttävä pikseli rekisterissä ARG0, vastauksena
; flagirekisterin FLAG_PISTE_TAYTETTY
; 1 jos piste on päällä ja 0 jos pois päältä.
sram_tarkista_pikseli:
    PUSH XL
    PUSH XH
    CBR REG_FLAGI,FLAG_PISTE_TAYTETTY       ; Tyhjä kunnes toisin todistetaan
    RCALL sram_pikselin_osoite              ; Hae pikselin dataosoite X-rekisteriin
    MOV REG_MUUT1,REG_PISTE                 ; Sarakkeen paikka kolmesta alimmasta bitistä
    CBR REG_MUUT1,0xF8
    LDI REG_LOOP1,PIX_SARAKE0
    LDI REG_LOOP2,PIX_SARAKE1
    LDI REG_MUUT2,0x01
_loop_sram_tarkista_pikseli_sarake:
    CP REG_LOOP1,REG_MUUT1
    BREQ _loop_sram_tarkista_pikseli_sarake_end
    ADD REG_LOOP1,REG_LOOP2
    LSL REG_MUUT2
    RJMP _loop_sram_tarkista_pikseli_sarake
_loop_sram_tarkista_pikseli_sarake_end:
    LD REG_MUUT1,X                           ; Hae kennodata ja katso
    POP XH                                   ; onko sarakkeen kohdalla 1 vai 0
    POP XL
    AND REG_MUUT1,REG_MUUT2
    BRNE _sram_tarkista_pikseli_taytetty
    RET
_sram_tarkista_pikseli_taytetty:             ; Pikselin arvo oli 1: aseta flagi
    SBR REG_FLAGI,FLAG_PISTE_TAYTETTY
    RET

; //condimport
.endif
