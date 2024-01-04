@echo off
REM Skripti jolla saa käännettyä valitun tiedostopolun assemblyn ajettavaksi heksaksi

set loc_avrasm2="C:\Program Files (x86)\Atmel\Studio\7.0\toolchain\avr8\avrassembler\avrasm2.exe"
set loc_avr_inc="C:\Program Files (x86)\Atmel\Studio\7.0\packs\atmel\ATtiny_DFP\1.10.348\avrasm\inc"

REM Oletuksena main.asm, mutta voi säätää
set tiedosto="./src/main.asm"
if "%~1"=="" goto KUTSUVAIHE
set tiedosto=%1

:KUTSUVAIHE
call %loc_avrasm2% -fI -o hex_out.hex -I %loc_avr_inc% %tiedosto%

REM Ei saatu käännettyä: lopeta suoritus
if ERRORLEVEL 1 exit /b

REM Saatiin käännettyä: lähetä raspille inboksikansioon
scp hex_out.hex piiportti:~/inbox/hex_out.hex

REM SCP epäonnistui (verkkovirhe tmv)
if ERRORLEVEL 1 exit /b

REM Käske raspin lähettää inboksin heksatiedosto sirulle
ssh piiportti "sudo /bin/bash /home/taira/skriptit/puske.sh -l attiny"
