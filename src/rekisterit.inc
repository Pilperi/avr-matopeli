; Rekisterimääritelmät
.ifndef REKISTERIT
.equ REKISTERIT=0

;-------------------------------------------------------------------------------
; 0-15

.def REG_NOPEUTUS    = R13
.def REG_RAND        = R14
.def REG_NOLLA       = R15

;-------------------------------------------------------------------------------
; 16-25
.def REG_MUUT1       = R16           ; Yleinen muuttujarekisteri
.def REG_MUUT2       = R17           ; Yleinen muuttujarekisteri

.def REG_LOOP1       = R18           ; Looppirekisteri 1
.def REG_LOOP2       = R19           ; Looppirekisteri 2

.def REG_ARG0        = R20           ; Yleinen kutsuargumentti 1
.def REG_ARG1        = R21           ; Yleinen kutsuargumentti 2
.def REG_ARG2        = R22           ; Yleinen kutsuargumentti 3

.def REG_FLAGI       = R23           ; Erinäiset statusflagit
.def REG_MATOSTATUS  = R24           ; Madon status
.def REG_RUOKAPISTE  = R25           ; Ruoan sijainti

;-------------------------------------------------------------------------------
; XYZ
.def REG_OSOITE_L    = R26           ; SRAMiin kirjoitusosoite (LOW)
.def REG_OSOITE_H    = R27           ; SRAMiin kirjoitusosoite (HIGH)
.def REG_OSVAR_L     = R28           ; Juoksevan osoitedatan rekisteri
.def REG_OSVAR_H     = R29           ; Juoksevan osoitedatan rekisteri
.def REG_PISTE_KENNO = R30           ; Kirjoitettavan pisteen kennonumero
.def REG_PISTE       = R31           ; Kirjoitettavan pisteen koordinaatit

; //condimport
.endif
