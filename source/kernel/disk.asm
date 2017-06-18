
; ------------------------------------------------------------------
; read_dir -- Read the files in the current dir
; IN/OUT: Nothing

read_dir:
	pusha
	mov	di, dirlist
	call reset_floppy
	mov	ch, 0
	mov	cl, 2
	mov	dh, 1
	mov	bx, file_buffer
	mov	al, 14
	mov	ah, 2
	pusha
  .load_root_dir:
	int	13h
    jnc	loaded_root_dir
	call  reset_floppy
	jmp	.load_root_dir
  loaded_root_dir:
	popa
	mov	si, file_buffer
  compare_entry:
	mov	al, [si+11]
	cmp	al, 0Fh			;Windows marker
	je	.skip_entry
	cmp	al, 18h			;Directory marker
	je	.skip_entry
	cmp	al, 229			;deleted file
	je	.skip_entry
	cmp	al, 0
	je	.done
	mov	dx, si
	mov	cx, 0
  .save_character:
	mov	BYTE al, [si]
	cmp	al, ' '
	je	.space
	mov	BYTE [di], al
	inc	di
	inc	si
	inc	cx
	cmp	cx, 8
	je	.add_dot
	cmp	cx, 11
	je	.string_copied
	jmp	.save_character
  .add_dot:
	mov	BYTE [di], '.'
	inc	di
	jmp	.save_character
  .space:
	inc	si
	inc	cx
	cmp	cx, 8
	je	.add_dot
	jmp	.save_character
  .string_copied:
	mov	BYTE [di], ','
	inc	di
	mov	si, dx
  .skip_entry:
	add	si, 32
	jmp	compare_entry
  .done:
	mov	si, dirlist
	mov ah, 0Eh
  .print:
	lodsb
	cmp	al, 0
	je	.done_printing
	cmp	al, ','
	je	.comma
	int	10h
	jmp	.print
  .comma:
	call newline
	jmp	.print
  .done_printing:
	popa
	ret


; ------------------------------------------------------------------
; find_file -- Find a file in the root directory
; IN: AX = Filename to find
; OUT: Carry flag on error/ not found

find_file:
    ; TODO: Implement string handling ex kernel.bin, to "KERNEL  BIN"
    push ax                     ; Preserve filename
    call load_root_dir          ; Load root dir contents into ram
    pop ax                      ; Restore filename 
    mov di, disk_buffer
    call get_root_entry         ; Search for the file
    ret


; ------------------------------------------------------------------
; load_root_dir -- Load the root directory contents into ram
; IN: Nothing;
; OUT: Root dir in disk_buffer, carry flag on error

load_root_dir:
    pusha
	mov ax, 19			        ; Root dir starts at logical sector 19
	call convert_sector
	mov si, disk_buffer		
	mov bx, ds
	mov es, bx
	mov bx, si
	mov	al, 14
	mov	ah, 2
	pusha
  .loading_loop:
    popa
	pusha
	stc				            ; A few BIOSes do not set properly on error
	int 13h				    
	jnc .done
	call reset_floppy		    ; Reset floppy disk
	jnc .loading_loop		    
	popa
	jmp .error		   
  .done:
    popa				
	popa				
	clc				            ; Clear carry (for success)
	ret
  .error:
	popa
	stc				            ; Set carry flag (for failure)
	ret


; --------------------------------------------------------------------------
; get_root_entry -- Search RAM copy of root dir for file entry
; IN: AX = Filename to find
; OUT: DI = Location of root dir entry, or carry set if file not found

get_root_entry:
	pusha
	mov ax, bx
	mov word [.file_temp], ax
	mov cx, 224			        ; Search all (224) entries
	mov ax, 0			        ; Searching at offset 0
  .search_root:
	push cx
	pop dx	        
	mov word si, [.file_temp]	; Start searching for filename
	mov cx, 11
	rep cmpsb
	je .found_file			    ; File was found!
	add ax, 32			        ; Each entry is 32 bytes
	mov di, disk_buffer		    ; Point to next root dir entry
	add di, ax
	push dx
	pop cx
	loop .search_root
	popa
	stc				            ; Set carry if entry not found
	ret
  .found_file:
	sub di, 11			        ; Move back to start of root dir entry
	mov word [.di_temp], di		; Restore all registers except for DI
	popa
	mov word di, [.di_temp]     ; Move value back to DI
	clc                         ; Clear carry (for success)
	ret

	.file_temp	    dw 0
	.di_temp		dw 0


; --------------------------------------------------------------------------
; convert_sector -- Calculate head, track and sector for int 13h
; IN: AX = logical sector 
; OUT: correct registers for int 13h

convert_sector:
	push bx
	push ax
	mov	bx, ax                  ; Save logical sector
	mov	dx, 0                   ; First the sector  
	div	WORD [SectorsPerTrack]  ; Sectors per track
	add	dl, 01h                 ; Physical sectors start at 1
	mov	cl, dl                  ; Sectors belong in CL for int 13h
	mov	ax, bx
	mov	dx, 0                   ; Calculate the head
	div	WORD [SectorsPerTrack]  ; Sectors per track
	mov	dx, 0
	div	WORD [Sides]            ; Floppy sides
	mov	dh, dl                  ; Head/side
	mov	ch, al                  ; Track
	pop	ax
	pop	bx
	mov	dl, [BootDrive]
	ret


; ------------------------------------------------------------------
; reset_floppy -- Reset the floppy disk on error
; IN: Nothing
; OUT: Carry flag on error

reset_floppy:
    push ax
    push dx

    mov	ax, 0
    mov	dl, BYTE [BootDrive]

    stc
    int	13h
    pop dx
    pop ax
    ret

