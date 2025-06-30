del %1.com 2>nul
del %1.hex 2>nul
del %1.prn 2>nul
del %1.asm 2>nul

ntvcm cc %1
ntvcm asm %1
ntvcm load %1


