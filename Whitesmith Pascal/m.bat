@echo off

ntvcm ptc -o prg.tm0 %1.pas
ntvcm cpp -o prg.tm1 -x prg.tm0
ntvcm cp1 -cem -b0 -n8 -u -o prg.tm2 prg.tm1
ntvcm cp2 -o prg.s prg.tm2
del prg.tm* 2>nul
ntvcm a80 -o prg.o prg.s
ntvcm lnk -u_main -eb__memory -tb0x100 -htr -o %1.com crtx.o prg.o libp.80 libc.80
del prg.o 2>nul
del prg.s 2>nul
