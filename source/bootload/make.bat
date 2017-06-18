@ECHO OFF
ECHO.
SET PATH=%PATH%;..\..\prog

ECHO Assembling bootloader...
nasm -f bin bootload.asm -o bootload.bin 
ECHO.

pause
exit