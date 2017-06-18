

timer:
	pusha
	mov ah, 86h
	mov cx, 20d
	int 15h
	popa

; ------------------------------------------------------------------
; clear_screen -- Clears the screen to the background
; IN/OUT: Nothing 

clear_screen:
	pusha
	mov dx, 0			; Position cursor at top-left
	call move_cursor

	mov ah, 6			; Scroll full-screen
	mov al, 0			; Normal white on black
	mov bh, 7			;
	mov cx, 0			; Top-left
	mov dh, 24			; Bottom-right
	mov dl, 79
	int 10h
	popa
	ret


; ------------------------------------------------------------------
; move_cursor -- Moves the cursor
; IN: DH, DL = row, column
; OUT: Nothing

move_cursor:
	pusha
	mov bh, 0
	mov ah, 2
	int 10h				; BIOS interrupt to move cursor
	popa
	ret


; ------------------------------------------------------------------
; draw_line -- Draws a line
; IN: 1, 2, 3 = x, y, len
; OUT: Nothing

%macro draw_line 3 
    ; %define screen_width  79d
    ; %define screen_height 24d 
    pusha

    mov dl, %1
    mov dh, %2 
    call move_cursor

    mov ah, 09h			    ; Draw white bar at top
	mov bh, 0
	mov cx, %3
	mov bl, 70h		; Black text on white background
	mov al, ' '
	int 10h

	popa
%endmacro

; ------------------------------------------------------------------
; os_draw_block -- Render block of specified colour
; IN: BL/DL/DH/SI/DI = colour/start X pos/start Y pos/width/finish Y pos

draw_block:
	pusha

.more:
	call move_cursor		; Move to block starting position

	mov ah, 09h			; Draw colour section
	mov bh, 0
	mov cx, si
	mov al, ' '
	int 10h

	inc dh				; Get ready for next line

	mov ax, 0
	mov al, dh			; Get current Y position into DL
	cmp ax, di			; Reached finishing point (DI)?
	jne .more			; If not, keep drawing

	popa
	ret

; ------------------------------------------------------------------
; draw_box -- Draws a box
; IN: 1, 2, 3 = x, y, len
; OUT: Nothing

%macro draw_box 3 
    ; %define screen_width  79d
    ; %define screen_height 24d 
    pusha

    mov dl, %1
    mov dh, %2 
    call move_cursor

    mov ah, 09h			    ; Draw white bar at top
	mov bh, 0
	mov cx, %3
	mov bl, 70h		; Black text on white background
	mov al, ' '
	int 10h

	popa
%endmacro



mouse:
    call clear_screen
 	mov ah, 01h
 	mov cx, 07h
 	int 10h

 	mov bl, 0h
 	mov cl, 0h

movement:
 	mov ah, 02h
 	mov dl, bl
 	mov dh, cl
 	int 10h
 
 	mov ah, 00h
 	int 16h
 
 	cmp al, 77h	
 	je .mov_up
 
 	cmp al, 73h
 	je .mov_down
 
 	cmp al, 61h
 	je .mov_left
 
 	cmp al, 64h
 	je .mov_right

	cmp al, 20h
	je .space

	cmp al, 1bh		; Excape char
    je excape

 	jmp movement

  .mov_up:			; Move cursor up
	cmp cl, 0h
	je movement
	sub cl, 1h
	jmp movement

  .mov_down:		; Move cursor down
	cmp cl, 24d
	je movement
	add cl, 1h
	jmp movement

  .mov_left:		; Move cursor left
	cmp bl, 0h
	je movement
	sub bl, 1h		
	jmp movement

  .mov_right:		; Move cursor right
	cmp bl, 79d
	je movement
	add bl, 1h
	jmp movement

  .space:			; Click key
	mov al, 77h
	mov ah, 0eh
	int 10h
	jmp movement

excape:
  call clear_screen
  ret


