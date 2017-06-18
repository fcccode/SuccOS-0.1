
; ==================================================================
; SuccOS -- The Succ Operating System Bootloader
; Copyright (C) 2017 - 2018 Joshua Riek
;
; The bootloader loads disk contents and
; will load the kernel into system ram 
; ==================================================================

	BITS 16

  ; -----------------------
  ; |   Set up stack      |
  ; -----------------------

	cli
	mov ax, 0x0000		
	mov ss, ax
	mov sp, 0xFFFF
	sti

  ; -----------------------
  ; |   Set up registers  |
  ; -----------------------
  
	mov ax, 07C0h		
	mov ds, ax
	mov es, ax

	mov [BootDrive], dl

  ; -----------------------
  ; |   Loading disk      |
  ; -----------------------
  
	mov	ch, 0			    ; Track
	mov	cl, 2			    ; Sector
	mov	dh, 1			    ; Head
	mov	bx, buffer		    ; Buffer
	mov	al, 14			    ; Number of sectors
	mov	ah, 2
    call load_kernel

bios_welcome:
	mov dx, 0			; Position cursor at top-left
	call move_cursor

	mov ah, 6			; Scroll full-screen
	mov al, 0			; Normal white on black
	mov bh, 7			;
	mov cx, 0			; Top-left
	mov dh, 24			; Bottom-right
	mov dl, 79
	int 10h             ; Clear the screen

    mov dx, 0
    call move_cursor

    mov ah, 09h			; Draw bar at top
	mov bh, 0
	mov cx, 80d
	mov bl, 70h		    
	mov al, ' '
	int 10h

    mov dx, 0
    call move_cursor
	mov si, boot_title  ; Print boot title
	call print  

	mov dh, 24d
    call move_cursor

    mov ah, 09h		    ; Draw bottom bar
	mov bh, 0
	mov cx, 80d
	mov bl, 70h		
	mov al, ' '
	int 10h

    mov dh, 5
    mov dl, 0
    call move_cursor
	mov si, boot_msg
	call print          ; Print the boot message

	mov ah, 0           ; Wait for keypress
	int     0x16
    ret

; ------------------------------------------------------------------
; load_kernel -- Load the kernel file 
; IN/OUT: Nothing

load_kernel:
    pusha
	int		13h
	jnc	.loaded_root
	call reset_floppy
	jmp	load_kernel
  .loaded_root:
	popa
	mov	di, buffer
	mov	cx, 224
	;mov ax, 0
  .search_root:
	push cx
	pop dx
	mov	si, Filename
	mov	cx, 11
	rep	cmpsb
	je  .found_file			; Found the file!
	add	ax, 32
	mov	di, buffer
	add	di, ax
	push dx
	pop	cx
	loop .search_root		; Cont search root for file
	int		18h				; Kernel not found!
  .found_file:
	mov	ax, WORD [di+15]
	mov	[FirstSector], ax	; Load file table
	mov	bx, buffer
	mov ax, 1
	call convert_sector
	mov	al, 9
	mov	ah, 2
	pusha
  .load_fat:
	int	13h
	jnc	.loaded_fat
	call reset_floppy
	jmp	.load_fat
  .loaded_fat:
    mov ah, 2
	mov al, 1
	push ax
  .load_file_sector:
    mov ax, WORD [FirstSector]
	add ax, 31
	call convert_sector
	mov ax, 2000h			; Load file into first sector/ RAM
	mov es, ax
	mov bx, WORD [Pointer]
	pop ax
	push ax
	int 13h
	jnc .calculate_next_sector
	call reset_floppy
	jmp .load_file_sector
  .calculate_next_sector:
    mov ax, [FirstSector]
	mov dx, 0
	mov bx, 6
	mul bx
	mov bx, 4
	div bx
	mov si, buffer
	add si, ax
	mov ax, WORD [si]
	or dx, dx
	jz .even
  .odd:
	shr ax, 4
	jmp short .next_sector_calculated
  .even:
    and ax, 0FFFh
  .next_sector_calculated:
	mov	WORD [FirstSector], ax
	cmp	ax, 0FF8h
	jae	.end
	add	WORD [Pointer], 512
	jmp	.load_file_sector
  .end:
    pop ax  
	mov dl, BYTE [BootDrive]

    call bios_welcome
    jmp 2000h:0000h         ; Jump to our loaded kernel
  

; ------------------------------------------------------------------
; convert_sector -- Convert fat12 sector
; IN/OUT: Nothing

convert_sector:
	push bx
	push ax
	mov	bx, ax
	mov	dx, 0
	div	WORD [SectorsPerTrack]
	add	dl, 01h
	mov	cl, dl
	mov	ax, bx
	mov	dx, 0
	div	WORD [SectorsPerTrack]
	mov	dx, 0
	div	WORD [Sides]
	mov	dh, dl
	mov	ch, al
	pop	ax
	pop	bx
	mov	dl, BYTE [BootDrive]
	ret

; ------------------------------------------------------------------
; reset_floppy -- Reset the floppy disk on error
; IN/OUT: Nothing

reset_floppy:			; Rest the floppy disk on error
	mov ah, 0
	mov dl, BYTE [BootDrive]
	int		13h
	ret


; ------------------------------------------------------------------
; print -- Print out a string
; IN: SI = String to print
; OUT: Nothing

print:
	lodsb				; Get character from string
	or al, al
	jz .done		    ; If char is zero, end of string
	mov ah, 0x0E		; int 10h 'print char' function
	int     0x10		; Otherwise, print it
	jmp print
  .done: 
    ret


; ------------------------------------------------------------------
; move_cursor -- Moves the cursor
; IN: DH, DL = row, column
; OUT: Nothing

move_cursor:
	mov bh, 0
	mov ah, 2
	int 10h				; BIOS interrupt to move cursor
	ret
 
  ; -----------------------
  ; |     BIOS defines    |
  ; -----------------------
  
	SectorsPerTrack	dw 18
	FirstSector		dw 0
	BootDrive		db 0
	Sides			dw 2
	Pointer			dw 0
	Filename		db "KERNEL  BIN"	; Must be 11 bytes

  ; -----------------------
  ; |     BIOS strings    |
  ; -----------------------

    boot_title      db " SuccOS BIOS", 0
    boot_msg        db " Welcome to the SuccOS BIOS!", 10, 13, 
                    db " Copyright (C) 2017 - 2018 Joshua Riek", 10, 13,
                    db  10, 13, 10, 13, 10, 13, " Press any key to continue...", 0

  ; -----------------------
  ; |     BIOS signature  |
  ; -----------------------
  
	times 510-($-$$) db 0   ; Fill boot sector to 512 bytes
	dw 0xAA55               ; Boot sector signature 
	buffer:                 ; byte 513


