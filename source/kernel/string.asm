
; ------------------------------------------------------------------
; register_dump -- Print out all register values
; IN: DX = Register value to show
; IN: SI = Register string prefix
; OUT: Nothing

register_dump: 
    pusha
    call print
	mov si, hex_chars   ; Hex chars
	mov cx, 4           ; Times to loop
  .hex_loop:
	rol dx, 4           ; Rotate bits left 
	mov bx, 15          ; Hex char offset
	and bx,dx
	mov al, [si+bx]     
	mov ah, 0x0E		; Print the hex char
	int     0x10			
	loop .hex_loop
	call newline
	popa
	ret


; ------------------------------------------------------------------
; print -- Print out a string
; IN: SI = String to print
; OUT: Nothing

print:
    pusha
  .print_loop:
	lodsb				; Get character from string
	or al, al
	jz .done		    ; If char is zero, end of string
	mov ah, 0x0E		; int 10h 'print char' function
	int     0x10		; Otherwise, print it
	jmp .print_loop
  .done: 
    popa
    ret


; ------------------------------------------------------------------
; newline -- Print out a newline break
; IN/OUT: Nothing

newline:
    pusha
	mov al, 0		; null terminator
    stosb

    mov ah, 0x0e	; Adds a newline break '\n'
    mov al, 0x0D
    int		0x10
    mov al, 0x0a 
    int		0x10
    popa
    ret


; ------------------------------------------------------------------
; strcmp -- Compare command input with system command
; IN: DI = System command to compare
; OUT: Carry flag

strcmp:
	mov si, command
  .cmp_loop:
    mov al, [si]		; Byte from SI
    mov bl, [di]		; Byte from DI
    cmp al, bl			; Test if equal
    jne .notequal		
    cmp al, 0			; Both bytes equal before null?
    je .equal			
    inc di				
    inc si				
    jmp .cmp_loop			
  .notequal:
    clc					; Clear the carry flag
	ret
  .equal: 	
    stc					; Set the carry flag
	ret



; ------------------------------------------------------------------
; cmd_input -- Get user input and store in cmd_buffer
; IN/OUT: DI = Command line string buffer

cmd_input:
    pusha
    xor cl, cl
  .input_loop:
    mov ah, 0
    int		0x16		; Wait for keypress 
    cmp al, 0x08		; Handle backspace
    je .backspace   
    cmp al, 0x0d		; Handle enter
    je .done      
    cmp cl, 0x3f		; Handle max input buffer
    je .input_loop      
   
	mov bh, 0x00		; Page number
	mov bl, 0x0e		; Text color
	mov ah, 0x0e		; Print char function of 10h
	int		0x10		; Print out character

    stosb				; Store string
    inc cl
    jmp .input_loop
  .backspace:
    cmp cl, 0			; Start of string
    je .input_loop		
	dec di
    mov byte [di], 0	; Remove char
    dec cl				; Decrease char counter
   
    mov ah, 0x0e
    mov al, 0x08
    int 10h				; Backspace on the screen
    mov al, ' '
    int     10h			; Fill with blank char
    mov al, 0x08		
    int     10h		   
    jmp .input_loop		; go to the main loop
  .done: 
    call newline
    popa
    ret


; ------------------------------------------------------------------
; split_commands -- Split input buffer into command and param
; IN/OUT: DI = Command buffer
; IN/OUT: SI = User input buffer

split_commands:
    pusha
    xor cl, cl
  .command_loop:
	lodsb
    stosb				
	or al, al
	jz .done	
	cmp byte [si], ' '
	je .break
    inc cl
    jmp .command_loop
  .break:
  	dec si
	mov byte [si], 0		; Zero-terminate command
    add si, 2

    mov di, 0
    mov di, param
  .param_loop: 
    lodsb
    stosb
    or al, al
	jz .done	
    inc cl
    jmp .param_loop
  .done:
    dec si
    mov byte [si], 0        ; Zero-terminate param
    inc si
    popa
    ret


