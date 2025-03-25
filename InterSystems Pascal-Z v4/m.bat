@echo off
setlocal

del %1.src 2>nul
del %1.org 2>nul
del %1.com 2>nul
del %1.lst 2>nul
del %1.rel 2>nul

ntvcm Pascal48 %1

rem pasopt requires a byte RAM to be non-zero to work. It depends on some other
rem app having run to initialize that memory. 
rem The byte's location is -30eH bytes from the BDOS address.
rem NTVCM has a workaround. Comment this out if your emulator doesn't do this.
ntvcm pasopt %1.SRC

ntvcm asmbl main,%1/rel

rem /e means link. /g means link and run
ntvcm link %1 /n:%1 /e

ntvcm -c -p %1




