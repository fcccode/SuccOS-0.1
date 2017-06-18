; ==================================================================
; SuccOS -- The Succ Operating System kernel
; Copyright (C) 2017 - 2018 Joshua Riek
;
; The bootloader loads this file as the operating 
; system kernel. All kernel functions and commands
; are linked from the below included files. 
; ==================================================================


    bits 16                     ; Tell assembler to use 16 bit code
    disk_buffer	equ	24576
    ; %define debug 1


  ; -----------------------
  ; |   Set up stack      |
  ; -----------------------
	cli                         ; Clear interrupts
	mov	ax, 0   
	mov	ss, ax                  ; Set stack pointer
	mov	sp, 0FFFFh
	sti                         ; Restore interrupts

  ; -----------------------
  ; |   Set up segments   |
  ; -----------------------
  
	mov	ax, 2000h               ; Set segments to match where the kernel loaded 
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax

	mov	[BootDrive], dl         ; Save the boot drive number

  ; -----------------------
  ; |     Jump to cli     |
  ; -----------------------

    jmp cli_main


; ------------------------------------------------------------------
; Kernel Files -- Code to pull into the kernel

    %include "source\kernel\cli.asm"
    %include "source\kernel\screen.asm"
	%include "source\kernel\string.asm"
	%include "source\kernel\disk.asm"

