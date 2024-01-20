; Madon hallinta
.ifndef MATO
.equ MATO=0

; Matostatuksen rakenne
; Suunta/4 |    RESERVED       |
;  S1 S0   | P5 P4 P3 P2 P1 P0 |
.equ MATO_SUUNTA_OIKEA  = 0<<6
.equ MATO_SUUNTA_ALAS   = 1<<6
.equ MATO_SUUNTA_VASEN  = 2<<6
.equ MATO_SUUNTA_YLOS   = 3<<6


; Flagirekisterin flagit
.equ FLIND_MATO_KUOLLUT  = 0
.equ FLIND_PISTE_TAYTETTY= 1
.equ FLIND_PISTE_RUOKAA  = 2
.equ FLIND_VAIHDETTU     = 3
.equ FLIND_SAI_RUOKAA    = 4
.equ FLIND_VAARA         = 5
.equ FLIND_ARMOA_ANNETTU = 6
.equ FLAG_MATO_KUOLLUT   = 1<<FLIND_MATO_KUOLLUT
.equ FLAG_PISTE_TAYTETTY = 1<<FLIND_PISTE_TAYTETTY
.equ FLAG_PISTE_RUOKAA   = 1<<FLIND_PISTE_RUOKAA
.equ FLAG_VAIHDETTU      = 1<<FLIND_VAIHDETTU
.equ FLAG_SAI_RUOKAA     = 1<<FLIND_SAI_RUOKAA
.equ FLAG_VAARA          = 1<<FLIND_VAARA
.equ FLAG_ARMOA_ANNETTU  = 1<<FLIND_ARMOA_ANNETTU

.equ MADON_ALKUPAIKKA = PIX_KENNO1|PIX_SARAKE4|PIX_RIVI3
.equ MADON_ALKUPITUUS = 2
.equ MADON_ALKUSUUNTA = MATO_SUUNTA_YLOS

; Alusta mato.
; ykköskennon keskellä, kahden pituinen, menossa alaspäin
mato_init:
    LDI REG_MATOSTATUS,MADON_ALKUSUUNTA
    LDI REG_PITUUS,MADON_ALKUPITUUS
    RCALL sram_alusta_matodatat
    RET


; Aseta ruokapikseli hakemalla pseudosatunnainen koordinaatti
; laskurirekisteristä, ja etsimällä siitä lähin ei-täytetty piste
mato_aseta_ruoka:
    MOV REG_PISTE,REG_RAND
_mato_aseta_ruoka_loop:
    INC REG_PISTE
    RCALL sram_tarkista_pikseli
    MOV REG_MUUT1,REG_FLAGI
    ANDI REG_MUUT1,FLAG_PISTE_TAYTETTY
    BRNE _mato_aseta_ruoka_loop
    MOV REG_RUOKAPISTE,REG_PISTE
    RCALL sram_vaihda_pikseli
    LSL REG_RAND
    RET

; Liikuta matoa valittuun suuntaan.
; Suunta pitää olla validoituna ennen tätä.
mato_liiku:
    PUSH REG_ARG0
    LDS REG_ARG0,DAT_MATO            ; Nykyinen pää
    MOV REG_MUUT1,REG_MATOSTATUS     ; Madon etenemissuunta
    CBR REG_MUUT1,0x3F
    CPI REG_MUUT1,MATO_SUUNTA_OIKEA
    BREQ _mato_liiku_oikea
    CPI REG_MUUT1,MATO_SUUNTA_ALAS
    BREQ _mato_liiku_alas
    CPI REG_MUUT1,MATO_SUUNTA_YLOS
    BREQ _mato_liiku_ylos
_mato_liiku_vasen:
    LDI REG_MUUT1,PIX_RIVI1
    ADD REG_ARG0,REG_MUUT1
    RJMP _mato_liiku_piste_selvilla
_mato_liiku_oikea:
    LDI REG_MUUT1,PIX_RIVI1
    SUB REG_ARG0,REG_MUUT1
    RJMP _mato_liiku_piste_selvilla
_mato_liiku_alas:
    LDI REG_MUUT1,PIX_SARAKE1
    SUB REG_ARG0,REG_MUUT1
    RJMP _mato_liiku_piste_selvilla
_mato_liiku_ylos:
    LDI REG_MUUT1,PIX_SARAKE1
    ADD REG_ARG0,REG_MUUT1
_mato_liiku_piste_selvilla:
    RCALL mato_tarkista_kuolema       ; Tarkista kuoleeko tai kasvaako mato
    SBRS REG_FLAGI,FLIND_MATO_KUOLLUT ; Jos ei kuolla,päivitä madon muistialue
    RCALL mato_paivita_datat
    POP REG_ARG0
    RET


; Tarkista kuoleeko mato liikkeestä
; eli onko seuraava piste (ARG0) ei-ruoka päällä oleva pikseli
mato_tarkista_kuolema:
    MOV REG_PISTE,REG_ARG0
    RCALL sram_tarkista_pikseli
    SBRS REG_FLAGI,FLIND_PISTE_TAYTETTY ; Jos pistettä ei ole täytetty, ei voi kuolla
    RET
    CPSE REG_PISTE,REG_RUOKAPISTE       ; Jos ruokapiste, kaikki on ok
    RJMP mato_tarkista_kuolema_vaarassa
    CBR REG_FLAGI,FLAG_VAARA            ; Jos oli vaarassa, ei ole enää
    SBR REG_FLAGI,FLAG_PISTE_RUOKAA
    RCALL mato_aseta_ruoka              ; Uusi ruokapiste
    RET
mato_tarkista_kuolema_vaarassa:
    SBRC REG_FLAGI,FLIND_VAARA          ; Aika kuolla, olit jo vaarassa
    RJMP mato_tarkista_kuolema_tapa_mato
    SBR REG_FLAGI,FLAG_VAARA
    RET
mato_tarkista_kuolema_tapa_mato:
    CBR REG_FLAGI,FLAG_VAARA            ; Vaara on lievä termi
    SBR REG_FLAGI,FLAG_MATO_KUOLLUT
    RET


; Laita madon kaikki pisteet päälle tai pois päältä.
mato_toggle:
    PUSH XL
    PUSH XH
    LDI REG_LOOP1,0
    MOV REG_LOOP2,REG_PITUUS
    LDI XL,LOW(DAT_MATO)
    LDI XH,HIGH(DAT_MATO)
_mato_toggle_loop:
    LD REG_PISTE,X+
    PUSH REG_LOOP1
    PUSH REG_LOOP2
    RCALL sram_vaihda_pikseli
    POP REG_LOOP2
    POP REG_LOOP1
    INC REG_LOOP1
    CPSE REG_LOOP1,REG_LOOP2
    RJMP _mato_toggle_loop
    POP XH
    POP XL
    RET


; Päivitä madon datat muistissa.
; Seuraava piste oltava REG_ARG0:ssa ennen tämän kutsumista.
mato_paivita_datat:
    PUSH XL
    PUSH XH
    LDI XL,LOW(DAT_MATO)
    LDI XH,HIGH(DAT_MATO)
    MOV REG_LOOP1,REG_PITUUS         ; Madon pituus
    DEC REG_LOOP1
    ADD XL,REG_LOOP1
    ADC XH,REG_NOLLA
    MOV YL,XL
    MOV YH,XH
    LD REG_PISTE,X                   ; Vanha häntäpiste
    SBRC REG_FLAGI,FLIND_PISTE_RUOKAA
    RJMP _mato_paivita_datat_kasvata_matoa
    PUSH REG_LOOP1                   ; Vanha loppupää pois
    RCALL sram_vaihda_pikseli       
    POP REG_LOOP1
    RJMP _mato_paivita_datat_loop
_mato_paivita_datat_kasvata_matoa:   ; Vanha loppupää yhden kauemmas
    INC REG_PITUUS
    INC XL
    ADC XH,REG_NOLLA
    ST X,REG_PISTE
    MOV XL,YL                        ; Vanha loppupää takaisin osoitteeksi
    MOV XH,YH
_mato_paivita_datat_loop:
    LD REG_MUUT1,-Y                  ; Lataa arvo Y = X-1
    ST X,REG_MUUT1                   ; osoitteeseen X
    MOV XL,YL                        ; ja X = X-1, Y = Y-1
    MOV XH,YH
    DEC REG_LOOP1
    BRNE _mato_paivita_datat_loop
    STS DAT_MATO,REG_ARG0            ; Lopuksi uusi pää paikalleen
    MOV REG_PISTE,REG_ARG0
    RCALL sram_tarkista_pikseli      ; Jos uusi pää on jo päällä, älä vaihda tilaa
    SBRS REG_FLAGI,FLIND_PISTE_TAYTETTY
    RCALL sram_vaihda_pikseli
    POP XH
    POP XL
    SBRS REG_FLAGI,FLIND_PISTE_RUOKAA ; Jos piste oli ruokaa, fläshää
    RET
    CBR REG_FLAGI,FLAG_PISTE_RUOKAA
    RCALL mato_toggle
    SBR REG_FLAGI,FLAG_SAI_RUOKAA
    RET

;//condimport
.endif