.include "rekisterit.inc"
.include "pinnit.inc"


.cseg
.org 0x0000
RJMP pohjusta
RETI               ; INT0
RJMP nappi_ov_muutos  ; PCINT0         Pinin tila muuttuu
RETI               ; TIMER1_COMPA
RJMP uusi_random   ; TIMER1_OVF
RETI               ; TIMER0_OVF
RETI               ; EE_RDY
RETI               ; ANA_COMP
RETI               ; ADC
RETI               ; TIMER1_COMPB
RJMP aika_umpeen   ; TIMER0_COMPA
RETI               ; TIMER0_COMPB
RETI               ; WDT
RETI               ; USI_START
RETI               ; USI_OVF

; Pohjustus: stack pointteri kohdilleen, aseta väylä kolmipiuhaksi
pohjusta:
    LDI REG_MUUT1,0x00
    MOV REG_FLAGI,REG_MUUT1
    LDI REG_MUUT1,0xAA
    MOV REG_RAND,REG_MUUT1
    LDI REG_MUUT1,0x00
    MOV REG_NOLLA,REG_MUUT1
    LDI REG_PISTE,0x00
    LDI	REG_MUUT1,LOW(RAMEND)     ; Stack pointer kohdilleen
	OUT	SPL,REG_MUUT1
	LDI	REG_MUUT1,HIGH(RAMEND)
	OUT	SPH,REG_MUUT1
    RCALL sram_alusta
pohjusta_interrupt:
; Aika umpeen
    LDI REG_MUUT1,(1<<COM0A1)|(0<<COM0A0)|(1<<WGM01)
    OUT TCCR0A,REG_MUUT1
    LDI REG_MUUT1,(1<<CS00)|(1<<CS02)|(1<<FOC0A)
    OUT TCCR0B,REG_MUUT1
    LDI REG_MUUT1,0x8F      ; Alkunopeus
    OUT OCR0A,REG_MUUT1
    LDI REG_MUUT1,0x00
    OUT TCNT0,REG_MUUT1
    LDI REG_MUUT1,(1<<OCIE0A)|(1<<TOIE1)
    OUT TIMSK,REG_MUUT1
; Toinenkin laskuri käynnissä (satunnaislähde)
    LDI REG_MUUT1,(0<<CS13)|(0<<CS12)|(0<<CS11)|(1<<CS10) ; Täyttä hönkää
    OUT TCCR1,REG_MUUT1
pohjusta_max:
    RCALL aseta_spi
    RCALL max7219_init
    RCALL vapauta_spi
pohjusta_mato:
    RCALL mato_init
    RCALL mato_aseta_ruoka

main:
    CLI
    RCALL aseta_spi
    RCALL max7219_piirra_kuva
    RCALL vapauta_spi
    SEI
    SLEEP
    RJMP main

aseta_spi:
    LDI REG_MUUT1,(1<<PIN_MOSI)
    OUT PORTB,REG_MUUT1
    LDI REG_MUUT1,(1<<PIN_MOSI)|(1<<PIN_CLK)|(1<<PIN_CSEL)
    OUT DDRB,REG_MUUT1
    LDI REG_MUUT1,(1<<USIWM0)|(1<<USICS1)|(1<<USICLK)
    OUT USICR,REG_MUUT1
    RET

vapauta_spi:
    LDI REG_MUUT1,0x00
    OUT USICR,REG_MUUT1
    LDI REG_MUUT1,(1<<PCIE)       ; Muutos PIN_NAPPI tilassa aiheuttaa PCINT0-keskeytyksen
    OUT GIMSK,REG_MUUT1
    LDI REG_MUUT1,(1<<PIN_NAPPI_VASEN)|(1<<PIN_NAPPI_OIKEA)
    OUT PCMSK,REG_MUUT1
    RET

aika_umpeen:
    CLI
    CBR REG_FLAGI,FLAG_VAIHDETTU       ; Voi taas vaihtaa suuntaa
    SBRC REG_FLAGI,FLIND_MATO_KUOLLUT
    RJMP aika_umpeen_vilauta_matoa
    SBRC REG_FLAGI,FLIND_VAARA         ; Törmäysvaarassa annetaan yksi freimi armoa
    RJMP aika_umpeen_armofreimi
    SBRS REG_FLAGI,FLIND_SAI_RUOKAA    ; Laitettu pois päältä ruoan takia
    RJMP aika_umpeen_liiku
    CBR REG_FLAGI,FLAG_SAI_RUOKAA
    RCALL mato_toggle
aika_umpeen_armofreimi:
    SBRC REG_FLAGI,FLIND_ARMOA_ANNETTU  ; Armoa on jo annettu, aika liikkua
    RJMP aika_umpeen_liiku
    SBR REG_FLAGI,FLAG_ARMOA_ANNETTU    ; Merkataan että armoa on annettu
    RJMP aika_umpeen_valmis             ; muttei liikuta
aika_umpeen_liiku:
    RCALL mato_liiku
    RJMP aika_umpeen_valmis
aika_umpeen_vilauta_matoa:
    RCALL mato_toggle
aika_umpeen_valmis:
    SEI
    RETI


uusi_random:
    INC REG_RAND
    RETI


nappi_ov_muutos:
    SBRC REG_FLAGI,FLIND_MATO_KUOLLUT  ; Mato on kuollut
    ; RETI
    RJMP pohjusta
    SBRC REG_FLAGI,FLIND_VAIHDETTU     ; Suuntaa on jo vaihdettu tikkausta varten
    RETI
    CLI
    IN REG_MUUT1,PINB
    CBR REG_MUUT1,0xF6
    CPI REG_MUUT1,PIN_NAPPI_OIKEA
    BREQ nappi_ov_muutos_vasen
    CPI REG_MUUT1,1<<0
    BREQ nappi_ov_muutos_vasen
    CPI REG_MUUT1,1<<3
    BREQ nappi_ov_muutos_oikea
    SEI
    RETI                               ; Molemmat ylhäällä
nappi_ov_muutos_oikea:
    SBR REG_FLAGI,FLAG_VAIHDETTU       ; Ei toista suunnanvaihdosta ennen seuraavaa ruutua
    MOV REG_MUUT1,REG_MATOSTATUS
    LDI REG_MUUT2,1<<6
    ADD REG_MUUT1,REG_MUUT2
    CBR REG_MUUT1,0x3F                 ; Nollaa pituusosa
    CBR REG_MATOSTATUS,0xC0            ; Nollaa suunta
    OR REG_MATOSTATUS,REG_MUUT1        ; Yhdistä
    SEI
    RETI
nappi_ov_muutos_vasen:
    SBR REG_FLAGI,FLAG_VAIHDETTU
    MOV REG_MUUT1,REG_MATOSTATUS
    LDI REG_MUUT2,1<<6
    SUB REG_MUUT1,REG_MUUT2
    CBR REG_MUUT1,0x3F                 ; Nollaa pituusosa
    CBR REG_MATOSTATUS,0xC0            ; Nollaa suunta
    OR REG_MATOSTATUS,REG_MUUT1        ; Yhdistä
    SEI
    RETI
    

.include "fun_max7219.asm"
.include "data.asm"
.include "mato.asm"
