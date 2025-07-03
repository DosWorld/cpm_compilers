del %1.COM 2>nul
del %1.HEX 2>nul
del DRIVE2.HEX 2>nul

ntvcm BCPL %1
ntvcm LINK DRIVE2,BCPL2,%1,BRTS,RTS2 /U

ren DRIVE2.HEX %1.HEX

ntvcm LOAD %1

del %1.HEX
del %1.OBJ

