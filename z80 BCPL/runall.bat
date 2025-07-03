@echo off
setlocal

set outputfile=test_bcpl.txt
echo %date% %time% >%outputfile%

set _testlist=e sieve ttt

( for %%t in (%_testlist%) do ( call :testRun %%t ) )

diff baseline_%outputfile% %outputfile%

goto :eof

:deleteArtifacts

set _artifactlist=com

( for %%a in (%_artifactlist%) do ( if exist "%~1.%%a" ( del %~1.%%a ) ) )

exit /b 0

:testRun

echo   test %~1

call :deleteArtifacts %~1
echo test case %~1 >>%outputfile%
call m.bat %~1 >>%outputfile%
ntvcm %~1.com  >>%outputfile%

call :deleteArtifacts %~1

exit /b 0

:eof


