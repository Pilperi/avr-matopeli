; Pinnimääritelmät
; ----------------
; PINB0
; PIN_MISO
; PIN_NAPPI_VASEN
;   Master data in mutta master ei ota dataa sisään, käytetään tuplakäytössä
;   niin että toinen ohjausnapeista on kytketty siihen sisääntuloksi.
;   Kytketty vastuksella maahan, ja napin painaminen vie jännitteen ylös.
;   Kaverina pieni konkka, koska muuten tulisi oskillaatiota ja tuplaklikkauksia.
;
; PINB1
; PIN_MOSI
;   Master data out, dataväylä näytön suuntaan.
;
; PINB2
; PIN_CLK
;   Kelloväylä SPI-yhteydelle.
;
; PINB3
; PIN_NAPPI
; PIN_NAPPI_OIKEA
;   Nappi madon kääntämiselle. Jossain kohtaa oli ainoa nappi, siksi nimi.
;   Kytketty vastuksella maahan, ja napin painaminen vie jännitteen ylös.
;   Kaverina pieni konkka, koska muuten tulisi oskillaatiota ja tuplaklikkauksia.
;
; PINB4
; PIN_CSEL
;   Chip Enable näyttöpiirille. Vastuksella maassa, ajetaan erikseen ylös.
;
; PINB5
; PIN_RST
;   Reset-pinni, ei yhdistetty.


.ifndef PINNIT
.equ PINNIT=0

.ifndef PINB0
.include "tn85def.inc"
.endif

.equ PIN_MISO     = PINB0            ; Master data in
.equ PIN_MOSI     = PINB1            ; Master data out
.equ PIN_CLK      = PINB2            ; Kellopinni
.equ PIN_NAPPI    = PINB3            ; Nappi-inputti
.equ PIN_CSEL     = PINB4            ; Chip enable
.equ PIN_RST      = PINB5            ; Reset-pinni

.equ PIN_NAPPI_OIKEA = PINB3         ; Käännä matoa oikealle
.equ PIN_NAPPI_VASEN = PINB0         ; Käännä matoa vasemmalle

;//condimport
.endif
