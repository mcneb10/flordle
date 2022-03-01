[bits 16]

org 0x7C00
build: 	mov [BOOTDRV], dl ; save boot drive
	mov esp, 0x7000 ; set stack pointer to 0x7000
	; read words
	xor ax, ax	; ax=0
	mov es, ax	; es=0
	mov ah, 2	; read mode
	mov al, 17	; read 23 sectors in total (17 now)
	mov ch, 0	; start at cylinder 0
	mov cl, 2	; start at sector 2
	mov dh, 0	; head 0
	mov bx, 0x7E00  ; store data at 0x7E00
	mov dl, [BOOTDRV] ; set boot drive
	int 13h		; read!
	mov ah, 2	; read mode again
	mov al, 6	; read last 16 sectors
	mov ch, 0 	; still cylinder 0
	mov cl, 1 	; start at sector 1 (of head 1)
	mov dh, 1 	; head 1
	mov bx, 0xA000 	; store data at 0xA000 (right after data we read before) 17x512=8704 in hex thats 0x2200 0x2200+0x7E00=0xA000
	mov dl, [BOOTDRV] ; still read from boot drive
	int 13h		; read again
Main:   mov bx, welcome ; load pointer to welcome message into bx
	call println	; print welcome message
	mov bx, prompt	; load ptr to prompt
	call println	; print prompt
pil: 	xor ah, ah	; ah=0 (get keyboard input mode)
  int 16h		; actually get it
	cmp al, 's'	; is it s
	je game		; if so start the game
	cmp al, 'e'	; is it e
	je shutdown	; if so shutdown
	jmp pil		; otherwise keep getting input
shutdown:mov ax, 0x5301
	xor bx,bx
	int 15h
	xor bx,bx
	mov ax, 0x530E
	mov cx, 0x0102
	int 15h
	mov ax, 0x5307
	mov bx, 1
	mov cx, 3
	int 15h
	jmp $		; we should never get here
game:	;read time (used to generate entropy for answer)
	cli
	xor al, al
	out 0x70, al
	in al, 0x71
	mov [SECOND], al
	mov al, 2
	out 0x70, al
	in al, 0x71
	mov [MINUTE], al
	mov al, 4
	out 0x70, al
	in al, 0x71
	mov [HOUR], al
	sti
	;make the seed
	mov al, [SECOND]
	mov ah, [HOUR]
	xor al, [MINUTE]
	xor ah, [MINUTE]
	; generate the random number
	; algorithm: x = (69 * seed + 420) mod 11470
	mov cx, 420
	mul cx
	add eax, 69	
	; make it fit (mod 11470) then make multiple of 5
	xor edx, edx
	mov	ecx, 11470
	div ecx
	xor edx, edx
	push eax
	; dividend already in eax
	mov ecx, 5
	div ecx
	pop eax
	sub eax, edx
	push eax
	; find the word
	mov ax, 1
	int 10h
	pop ebx
	add ebx, 0x7E00
	mov ah, 0x0E
	mov al, [ebx]
	int 10h
	inc ebx
	mov al, [ebx]
	int 10h
	inc ebx
	mov al, [ebx]
	int 10h
inc ebx
	mov al, [ebx]
	int 10h
	inc ebx
	mov al, [ebx]
	int 10h
	
iloop:	xor ah, ah
	int 16h
	mov ah, 0x0E
	int 10h
	inc byte [CHARC]
	cmp byte [CHARC],5
	jne iloop
	call newline
	
	jmp $
print:  mov ah, 0x0E
.loop:  mov al, [bx]
	cmp al, 0
	je done
	int 10h
	inc bx
	jmp .loop
done:	ret
newline:mov al, 0x0A
	mov ah, 0x0E
	int 10h
	mov al, 0x0D
	int 10h
	ret
println:call print
	call newline
	ret

hello: db 'Hello, World!', 0
welcome: db 'Welcome for FLORDLE (FLoppy disk wORDLE)', 0
prompt: db 'Press s to start or e to shut down your computer', 0

BOOTDRV: db 0
CHARC: db 0
SECOND: db 0
MINUTE: db 0
HOUR: db 0

times 510-($-$$) db 0
dw 0xAA55

%include "words.asm"

; vim: filetype=nasm	
