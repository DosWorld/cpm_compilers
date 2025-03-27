del %1.lst >nul 2>&1
del %1.com >nul 2>&1

ntvcm -c z80asm %1/SXA

del %1.lst >nul 2>&1

