@echo off

del %1.com 2>nul
del %1.rel 2>nul
del %1.mac 2>nul
del %1.prn 2>nul
del %1.sym 2>nul

ntvcm plmx %1 ;C+L+
ntvcm m80 =%1 /L
ntvcm link %1,BDOSCALL,RLIB[S]

del %1.rel 2>nul
del %1.mac 2>nul
del %1.prn 2>nul
del %1.sym 2>nul

