org 0x7C00
bits 16

jmp start

hang: jmp hang

to_game:
	mov si, LoadMSG
	call Print
	XOR BX, BX   		; Reset value of register to ensure that the buffer offset is 0
	MOV AH, 0x2  		; 2 = Read USB drive
	MOV AL, 0x8  		; Read eight sectors
	MOV CH, 0x0  		; Track 1
	MOV CL, 0x2  		; Sector 2, track 1
	MOV DH, 0x0  		; Head 1
	INT 0x13
	JC to_game   		; If failure, run to_game again.

	JMP 0x1000:0000 	; Jump to 0x1000, this is the start of the game

Print:
	lodsb
	or al, al
	jz printdone
	mov ah, 0x0E
	int 0x10
	jmp Print

printdone: ret

setvideomode:
	mov ah, 0x00
	mov al, 0x13
	int 0x10

start:
	xor ax, ax
	mov ds, ax
	mov es, ax
	
	cli
	mov ss, ax      ; Stack starts at segment 0x0 (relative to 0x7C00)
	mov sp, 0x9C00  ; Offset 0x9C00 (SS:SP)
	sti

	XOR AX, AX   		; Reset value of register
    INT 0x13
	jc start

	MOV AX, 0x1000		; When we read the sector, we are going to read address 0x1000
    MOV ES, AX     		; Set ES with 0x1000
	
	push dx
	
	mov si, HelloMSG
	call Print

	jmp to_game
	
HelloMSG db "Hello World from Pablo OS!!" , 0x0D, 0x0A, 0
LoadMSG db "Loading Tetris...", 0x0D, 0x0A, 0
CRLF db 0x0D, 0x0A, 0

times 510-($-$$) db 0
dw 0xAA55
