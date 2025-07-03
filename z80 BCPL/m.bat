del %1.com 2>nul
del %1.out 2>nul

ntvcm bcpl %1.B %1.OUT
ntvcm loadb %1.OUT %1.COM

del %1.out 2>nul

