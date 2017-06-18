
  ; -----------------------
  ; |     Cli strings     |
  ; -----------------------
	help_	            db "help     - Show commands.", 10, 13, 0
	dir_	            db "dir      - Display root directory.", 10, 13, 0
	version_		    db "version  - Display the OS version.", 10, 13, 0
	gui_			    db "gui      - Graphics testing.", 10, 13, 0
	cls_		        db "cls      - Clear the screen.", 10, 13, 0
	reg_                db "reg      - Show all register contents.", 10, 13, 0
	echo_		   	    db "echo     - Print out a string.", 10, 13, 0
	shutdown_		    db "shutdown - Shutdown the computer.", 10, 13, 0
	reboot_			    db "reboot   - Restart the comptuer.", 10, 13, 0

	copyright			db "Copyright (C) 2017 - 2018 Joshua Riek", 10, 13, 10, 13 ,0
	OSversion			db "SuccOS [version 0.0.1]", 10, 13, 0
	invalid_str			db "Bad command entered.", 10, 13, 0
	prompt				db "root@SuccOS:~$ ", 0
   
  ; -----------------------
  ; |   System commands   |
  ; -----------------------

    help			    db "help", 0
	dir				    db "dir", 0
	gui				    db "gui", 0
	cls				    db "cls", 0
	reg                 db "reg", 0
	echo			    db "echo", 0
	version			    db "version", 0
	shutdown		    db "shutdown", 0
	reboot			    db "reboot", 0 

  ; -----------------------
  ; |      Reg Dump       |
  ; -----------------------
  
    ax_reg              db "AX: 0x", 0
    bx_reg              db "BX: 0x", 0
    cx_reg              db "CX: 0x", 0
    dx_reg              db "DX: 0x", 0
    cs_reg              db "CS: 0x", 0
    ds_reg              db "DS: 0x", 0
    ss_reg              db "SS: 0x", 0
    es_reg              db "ES: 0x", 0
    gs_reg              db "GS: 0x", 0
    fs_reg              db "FS: 0x", 0
    sp_reg              db "SP: 0x", 0
    bp_reg              db "BP: 0x", 0
    si_reg              db "SI: 0x", 0
    di_reg              db "DI: 0x", 0
    
    Filename		db "KERNEL  BIN"	; Must be 11 bytes
  ; -----------------------
  ; |   String buffers    |
  ; -----------------------

    cmd_buffer times 64 db 0
    command    times 64 db 0
    param      times 64 db 0

  ; -----------------------
  ; |   Debug strings     |
  ; -----------------------
  
    debug_started       db "Debug mode activated!", 10, 13, 0

  ; -----------------------
  ; |       Drive         |
  ; -----------------------
  
	Sides dw 2
	SectorsPerTrack dw 18
    BootDrive			db 0
    dirlist	 times 1500	db 0
    
  ; -----------------------
  ; |        Misc         |
  ; -----------------------
  
    hex_chars           db "0123456789ABCDEF"	
    file_buffer         equ 24576


; ------------------------------------------------------------------
; Command Line Interface -- Main cli event loop handling

cli_main:
	call clear_screen           ; Clear screen 

	mov	dx, 0	                ; Set screen colors
	mov	ah, 09h 
	mov	al, ''
	mov	bh, 0
	mov	bl, 1eh	                ; Bg | sText color
	mov	cx, 2400
	int		10h

	mov si, OSversion           ; Print the current OS version
	call print
	mov si, copyright           ; Print out the copyright information
	call print 

    %ifdef debug                ; Debug start
    mov si, debug_started
    call print
    %endif

cli_loop:
    call clear_buffers

	call newline				; Print prompt
	mov si, prompt
    call print
   
	mov di, cmd_buffer          ; Get user input 
	call cmd_input

	mov si, cmd_buffer			; Ignore blank line   	
	cmp byte [si], 0           
	je cli_loop

	mov di, command	            ; Pharase user input
	mov si, cmd_buffer          
    call split_commands             

	mov di, help		        ; List commands
	call strcmp
	jc help_command

	mov di,	dir			        ; List dirs
	call strcmp
	jc dir_command

	mov di, gui			        ; Gui testing
	call strcmp
	jc gui_command

	mov di, cls		    	    ; Clear screen
	call strcmp
	jc cls_command

    mov di, reg                 ; Dump registers
    call strcmp 
    jc reg_command

	mov di, echo	            ; Echo string
	call strcmp
	jc echo_command

	mov di, version		        ; System version
	call strcmp
	jc version_command

    mov di, shutdown	        ; Shutdown system
    call strcmp
    jc shutdown_command

    mov di, reboot	    	    ; Reboot system
    call strcmp
    jc reboot_command

	mov si, invalid_str		    ; Invalid command
	call print
	jmp cli_loop  



; ------------------------------------------------------------------
; clear_buffers -- Clear input data and strings
; IN/OUT: Nothing

clear_buffers:
    pusha
	mov di, param			    ; Clear param buffer
	mov cx, 64
	rep stosb
	popa
	ret


; ------------------------------------------------------------------
; help_command -- Print out all commands
; IN/OUT: Nothing

help_command:
    mov si, help_
    call print
	mov si, dir_
	call print
	mov si, version_
	call print
	mov si, gui_
	call print
	mov si, cls_
	call print
	mov si, reg_
	call print
	mov si, echo_
	call print
	mov si, shutdown_
	call print
	mov si, reboot_
	call print

	jmp cli_loop


; ------------------------------------------------------------------
; dir_command -- Print out contents in root directory
; IN/OUT: Nothing

dir_command:
    mov ax, Filename
    call find_file
    
    ;call read_dir
    jmp cli_loop
    




; ------------------------------------------------------------------
; gui_command -- Graphics testing
; IN/OUT: Nothing

gui_command: 
	jmp cli_loop


; ------------------------------------------------------------------
; cls_command -- Clear the screen
; IN/OUT: Nothing

cls_command:
    call clear_screen
	mov	dx, 0	
	mov	ah, 09h
	mov	al, ''
	mov	bh, 0
	mov	bl, 1eh	                ; Bg | sText color
	mov	cx, 2400
	int		10h
	jmp cli_loop


; ------------------------------------------------------------------
; reg_command -- Dump registers
; IN/OUT: Nothing

reg_command:
    pusha

    mov si, ax_reg          ; AX
	mov dx, ax
	call register_dump
	mov si, bx_reg          ; BX
	mov dx, bx
	call register_dump
	mov si, cx_reg          ; CX
	mov dx, cx
	call register_dump
    mov si, dx_reg          ; DX
	mov dx, dx
	call register_dump
    mov si, cs_reg          ; CS
	mov dx, cs
	call register_dump
    mov si, ds_reg          ; DS
	mov dx, ds
	call register_dump
    mov si, dx_reg          ; DX
	mov dx, dx
	call register_dump
    mov si, ss_reg          ; SS
	mov dx, ss
	call register_dump
    mov si, es_reg          ; ES
	mov dx, es
	call register_dump
    mov si, gs_reg          ; GS
	mov dx, gs
	call register_dump
    mov si, fs_reg          ; FS
	mov dx, fs
	call register_dump
    mov si, sp_reg          ; SP
	mov dx, sp
	call register_dump
	mov si, bp_reg          ; BP
	mov dx, bp
	call register_dump
	mov si, si_reg          ; SI
	mov dx, si
	call register_dump
	mov si, di_reg          ; DI
	mov dx, di
	call register_dump
	popa
	jmp cli_loop

; ------------------------------------------------------------------
; echo_command -- Echo user input as string
; IN/OUT: Nothing

echo_command:
	mov si, param			; Ignore blank line   	

    cmp byte [si], 0   
    je .invalid_syntax

    cmp byte[si], ' '
    je .invalid_syntax

    call print
    call newline
    jmp cli_loop

  .invalid_syntax:
    mov si, .echo_invalid
 	call print
    jmp cli_loop

  .echo_invalid db "Error, invalid echo usage!", 10, 13, 0

; ------------------------------------------------------------------
; version_command -- Print out the OS version
; IN/OUT: Nothing

version_command:
	mov si, OSversion
	call print
	jmp cli_loop


; ------------------------------------------------------------------
; reboot_command -- Reboot the operating system
; IN/OUT: Nothing

reboot_command:
	db 0x0ea 
    dw 0x0000 
    dw 0xffff 


; ------------------------------------------------------------------
; shutdown_command -- Shutdown the operating system
; IN/OUT: Nothing

shutdown_command:
	mov ax, 0x1000
    mov ax, ss
    mov sp, 0xf000
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int		0x15
