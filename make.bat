@echo off
TITLE SuccOS build script


REM Close QEMU if open
tasklist /fi "imagename eq qemu-system-i386.exe" | find ":" > nul
if errorlevel 1 taskkill /f /im "qemu-system-i386.exe"  > nul

REM Program paths for dd.exe, imdisk.exe, nasm.exe
SET PATH=%PATH%;prog\


REM Compile the BOOTLOADER with nasm
REM ===================================================================
ECHO [93m[!] Assembling bootloader [0m

ECHO [31m
nasm -f bin source\bootload\bootload.asm -o source\bootload\bootload.bin 
ECHO [0m
IF NOT EXIST source\bootload\bootload.bin GOTO boot_failure

ECHO [92m	[+] Bootloader built successfully [0m && ECHO. && ECHO.
REM ==================================================================


REM Compile the KERNEL with nasm
REM ==================================================================
ECHO [93m[!] Assembling kernel [0m 

ECHO [31m
nasm -f bin source\kernel\kernel.asm -o source\kernel\kernel.bin
ECHO [0m
IF NOT EXIST source\kernel\kernel.bin GOTO kernel_failure

ECHO [92m	[+] Kernel built successfully [0m && ECHO.  && ECHO.
REM ==================================================================


REM Remove the last built image and copy an empty floppy disk image
REM ==================================================================
IF NOT EXIST built\formatted_floppy.img GOTO floppy_error
IF EXIST built\built_floppy.img GOTO remove_image
GOTO copy_image

:remove_image
DEL built\built_floppy.img > NUL

:copy_image
COPY built\formatted_floppy.img built\built_floppy.img > NUL
REM ==================================================================


REM MOUNT the floppy image to drive B:
REM ==================================================================
ECHO [93m[!] Mounting floppy disk image [0m  && ECHO.

ECHO [33m
imdisk -a -f built\built_floppy.img -s 1440K -m B:
ECHO [0m && ECHO.
IF NOT EXIST B: GOTO mount_failure


ECHO [92m	[+] Mounted floppy to drive B: [0m && ECHO. && ECHO.
REM ==================================================================


REM Copy files to the floppy disk
REM ==================================================================
ECHO [93m[!] Coppying files to floppy [0m && ECHO. && ECHO.

copy source\kernel\kernel.bin B: > NUL
IF NOT EXIST B:\kernel.bin GOTO copy_failure

ECHO  [92m	[+] Files successfully coppyed [0m && ECHO. && ECHO.
REM ==================================================================


REM UNMOUNT the floppy disk
REM ==================================================================
ECHO [93m[!] Unmounting floppy disk image  [0m && ECHO.

ECHO [33m
imdisk -D -m B:
ECHO [0m  && ECHO.
IF EXIST B: GOTO unmount_failure

ECHO  [92m	[+] Unmounted floppy at drive B: [0m && ECHO.  && ECHO.
REM ==================================================================


REM Write BOOTLOADER to disk image
REM ==================================================================
ECHO [93m[!] Writing bootsector to disk image [0m  && ECHO.

ECHO [33m
dd if=source\bootload\bootload.bin of=built\built_floppy.img bs=512
ECHO [0m  && ECHO.

ECHO  [92m	[+] Bootsector successfully written [0m && ECHO.  && ECHO.
REM ==================================================================


REM Run the built floppy disk image
REM ==================================================================
ECHO [93m[!] Running the floppy disk image [0m  && ECHO.

ECHO [33m
V:\Compilers\Assembly\qemu\qemu-system-i386.exe -fda built\built_floppy.img
ECHO [0m

EXIT
REM ==================================================================




:boot_failure
ECHO [91m	[-] Failed build the BOOTLOADER [0m && ECHO.
pause
exit

:kernel_failure
ECHO [91m	[-] Failed build the KERNEL [0m && ECHO.
pause
exit

:mount_failure
ECHO [91m	[-] Failed to MOUNT floppy to drive B: [0m && ECHO.
pause
exit

:floppy_error
ECHO [91m	[-] Failed to find FORMATTED floppy disk [0m && ECHO.
pause
exit

:copy_failure
ECHO [91m	[-] Failed to COPY files to floppy disk [0m && ECHO.
pause
exit

:unmount_failure
ECHO [91m	[-] Failed to UNMOUNT floppy in drive B: [0m && ECHO.
pause
exit

