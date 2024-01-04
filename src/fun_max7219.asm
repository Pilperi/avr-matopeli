; Juttelufunktiot MAX7219:lle
; Kommunikaatioväylä on pseudo-SPI: kaksi piuhaa muttei I2C
; vaan lähempänä SPI:tä (ts. ei startti- ja loppusignaaleja)
.ifndef MAX7219
.equ MAX7219 = 0


; MAX7219 komennot (osoitteet)
.equ MAX_CMD_NOP = 0x00  ; No operation
.equ MAX_CMD_D0  = 0x01  ; Digit 0
.equ MAX_CMD_D1  = 0x02  ; Digit 1
.equ MAX_CMD_D2  = 0x03  ; Digit 2
.equ MAX_CMD_D3  = 0x04  ; Digit 3
.equ MAX_CMD_D4  = 0x05  ; Digit 4
.equ MAX_CMD_D5  = 0x06  ; Digit 5
.equ MAX_CMD_D6  = 0x07  ; Digit 6
.equ MAX_CMD_D7  = 0x08  ; Digit 7
.equ MAX_CMD_DEC = 0x09  ; Decode Mode
.equ MAX_CMD_INT = 0x0A  ; Intensity
.equ MAX_CMD_SL  = 0x0B  ; Scan Limit
.equ MAX_CMD_SD  = 0x0C  ; Shutdown
.equ MAX_CMD_DT  = 0x0F  ; Display Test

; MAX7219 komentoargumentit
; Shutdown/Normal Operation
.equ MAX_DAT_SD_SHUTDOWN = 0x00  ; Shutdown
.equ MAX_DAT_SD_NORMAL   = 0x01  ; Normal Operation
; Decoding
.equ MAX_DAT_DEC_N = 0x00 ; No Decode
.equ MAX_DAT_DEC_0 = 0x01 ; Decode B digit 0
.equ MAX_DAT_DEC_3 = 0x0F ; Decode B digit 3-0
.equ MAX_DAT_DEC_7 = 0xFF ; Decode B digit 7-0
; Active
.equ MAX_DAT_LIM_0 = 0x00 ; Show only digit 0
.equ MAX_DAT_LIM_1 = 0x01 ; Show only digit 01
.equ MAX_DAT_LIM_2 = 0x02 ; Show only digit 012
.equ MAX_DAT_LIM_3 = 0x03 ; Show only digit 0123
.equ MAX_DAT_LIM_4 = 0x04 ; Show only digit 01234
.equ MAX_DAT_LIM_5 = 0x05 ; Show only digit 012345
.equ MAX_DAT_LIM_6 = 0x06 ; Show only digit 0123456
.equ MAX_DAT_LIM_7 = 0x07 ; Show only digit 01234567


;-------------------------------------------------------------------------------


; Siirrä kahdeksan bittiä
max7219_siirra_kahdeksan:
    SBI USICR,USITC              ; kello ylös ja kello alas
    SBI USICR,USITC
    SBIS USISR,USIOIF            ; tarkista onko kahdeksan siirtynyt
    RJMP max7219_siirra_kahdeksan
    RET


; Kopsaa data REG_ARG0-rekisteristä,
; komento REG_ARG1-rekisteristä ja
; tuuppaa USIDR kautta kennolle
max7219_laheta:
    PUSH REG_MUUT1
    LDI REG_MUUT1,0xF0
    OUT USISR,REG_MUUT1
    OUT USIDR,REG_ARG1
    RCALL max7219_siirra_kahdeksan  ; CMD
    OUT USISR,REG_MUUT1
    OUT USIDR,REG_ARG0
    RCALL max7219_siirra_kahdeksan  ; DATA
    POP REG_MUUT1
    RET


; Alusta kaikki kennot, tyhjää datat
max7219_init:
    LDI REG_ARG1,MAX_CMD_SD
    LDI REG_ARG0,MAX_DAT_SD_NORMAL  ; Normaali operaatiomoodi
    CBI PORTB,PIN_CSEL              ; Chip enable
    RCALL max7219_laheta
    RCALL max7219_laheta
    RCALL max7219_laheta
    RCALL max7219_laheta
    SBI PORTB,PIN_CSEL              ; Chip disable
    LDI REG_ARG1,MAX_CMD_SL         ; Kaikki rivit käytössä
    LDI REG_ARG0,MAX_DAT_LIM_7
    CBI PORTB,PIN_CSEL              ; Chip enable
    RCALL max7219_laheta
    RCALL max7219_laheta
    RCALL max7219_laheta
    RCALL max7219_laheta
    SBI PORTB,PIN_CSEL              ; Chip disable
    LDI REG_ARG1,MAX_CMD_D0         ; Nolladatat inee
    LDI REG_ARG0,0x00
_loop_max7219_init:
    CBI PORTB,PIN_CSEL              ; Chip enable
    RCALL max7219_laheta
    RCALL max7219_laheta
    RCALL max7219_laheta
    RCALL max7219_laheta
    SBI PORTB,PIN_CSEL              ; Chip disable
    INC REG_ARG1
    CPI REG_ARG1,MAX_CMD_D7+1
    BRNE _loop_max7219_init
    RET


; Piirrä yksittäinen rivi kaikkiin neljään kennoon.
; REG_ARG1 tulee olla asetettu oikeaksi riviksi
; ja X-rekisterin (REG_OSOITE_L/H) osoitettava haluttuun paikkaan
; ennen kutsua.
max7219_tayta_rivi:
    PUSH REG_LOOP1
    CBI PORTB,PIN_CSEL              ; Kennot päälle
    PUSH REG_OSOITE_L
    PUSH REG_OSOITE_H
    LDI REG_LOOP1,KENNOJA           ; Kuhunkin kennoon dataa
    LD REG_ARG0,X                   ; Data alkuosoitteesta
_loop_max7219_tayta_rivi:
    RCALL max7219_laheta
    ADIW XH:XL,RIVEJA_KENNOSSA      ; Sama rivi seuraavassa kennossa
    LD REG_ARG0,X
    DEC REG_LOOP1
    BRNE _loop_max7219_tayta_rivi
    SBI PORTB,PIN_CSEL              ; Latch
    POP REG_OSOITE_H
    POP REG_OSOITE_L
    POP REG_LOOP1
    RET


; Piirrä kaikki data uusiksi (päivitä ruutu)
max7219_piirra_kuva:
    PUSH REG_ARG1
    LDI REG_OSOITE_L,LOW(DAT_KENNO3)
    LDI REG_OSOITE_H,HIGH(DAT_KENNO3)
    LDI REG_ARG1,MAX_CMD_D0                  ; Looppaa rivien yli
_loop_piirra_kuva_kenno:
    RCALL max7219_tayta_rivi
    ADIW REG_OSOITE_H:REG_OSOITE_L,1         ; Nollakennon seuraava osoite (rivi)
    INC REG_ARG1
    CPI REG_ARG1,MAX_CMD_D7+1
    BRNE _loop_piirra_kuva_kenno
    POP REG_ARG1
    RET

;//condimport
.endif
