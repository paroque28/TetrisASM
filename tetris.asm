[BITS 16]
[ORG 0x10000]      ; This code is intended to be loaded starting at 0x1000:0x0000
                  ; Which is physical address 0x10000. ORG represents the offset
                  ; from the beginning of our segment.

; Our bootloader jumped to 0x1000:0x0000 which sets CS=0x1000 and IP=0x0000
; We need to manually set the DS register so it can properly find our variables


mov ax, cs
mov ds, ax   	; 



; ==============================================================================
; MACROS
; ==============================================================================

; Sleeps for the given number of microseconds.
%macro sleep 1
	pusha
	xor cx, cx
	mov dx, word [speed]
	mov ah, 0x86
	int 0x15
	popa
%endmacro

; Choose a brick at random.
%macro select_brick 0
	mov ah, 2                    ; get current time
	int 0x1a
	mov al, byte [seed_value]
	xor ax, dx
	mov bl, 31;1;31
	mul bx
	inc ax
	mov 	byte [seed_value], al
	xor dx, dx
	mov bx, 7;1;7
	div bx
	shl dl, 3;1;3
	xchg ax, dx                  ; mov al, dl
%endmacro

; Sets video mode and hides cursor.
%macro clear_screen 0
	xor ax, ax                   ; clear screen (40x25)
	int 0x10
	mov ah, 1                    ; hide cursor
	mov cx, 0x2607
	int 0x10
%endmacro

field_left_col:  equ 13
field_width:     equ 12
inner_width:     equ 10
inner_first_col: equ 14
start_row_col:   equ 0x0412


%macro init_screen 0
	clear_screen
	mov dh, 1                    ; row
	mov cx, 20                       ; number of rows
ia: push cx
	inc dh                           ; increment row
	mov dl, field_left_col           ; set column
	mov cx, field_width              ; width of box
	mov bx, 0xFF                     ; color
	call set_and_write
	cmp dh, 21                       ; don't remove last line
	je ib                            ; if last line jump
	inc dx                           ; increase column
	mov cx, inner_width              ; width of box
	xor bx, bx                       ; color
	call set_and_write
	
ib: pop cx
	loop ia
%endmacro




;Call the menu
%macro menu 0

;Set the video mode
	mov ah, 0x00 	
	mov al, 0x13	
	int 0x10

;Print the menu on screen	
	call menu_msg1
	call menu_msg2
	call menu_msg3
	call menu_msg4
	;call menu_msg5
	call wait_for_menu






menu_msg1:
	mov si, menu1
	mov bl, 10  ;white color 
	mov bh, 0   
	mov cx, 1	
	mov dh, 2	
	mov dl, 17	
	jmp msg_menu1

msgret1:
	ret
;Call the level 1 msg from the menu	
menu_msg2:
	mov si, menu2
	mov bl, 5   ;White color
	mov bh, 0   
	mov cx, 1	
	mov dh, 6	
	mov dl, 11	
	jmp msg_menu2
msgret2:
	ret
;Call the level 2 msg from the menu	
menu_msg3:
	mov si, menu3
	mov bl, 1  ;White color
	mov bh, 0   
	mov cx, 1	
	mov dh, 8	
	mov dl, 11	
	jmp msg_menu3
msgret3:
	ret
;Call the level 3 msg from the menu		
menu_msg4:
	mov si, menu4
	mov bl, 3   ;White color
	mov bh, 0   
	mov cx, 1	
	mov dh, 10	
	mov dl, 11	
	jmp msg_menu4
msgret4:
	ret
;Call the exit msg from the menu	
menu_msg5:
	mov si, menu5
	mov bl, 15   ;White color
	mov bh, 0   
	mov cx, 1	
	mov dh, 14	
	mov dl, 11	
	jmp msg_menu5
msgret5:
	ret

	
msg_menu1:
	mov ah, 0x2	
	int 10h
	lodsb	
	or al, al	
	jz msgret1
	mov ah, 0xa
	int 10h		
	inc dl		
	jmp msg_menu1


	
;Prints the level 1 msg
msg_menu2:
	mov ah, 0x2	
	int 10h
	lodsb		
	or al, al	
	jz msgret2
	mov ah, 0xa	
	int 10h		
	inc dl		
	jmp msg_menu2	
;Prints the level 2 msg
msg_menu3:
	mov ah, 0x2	
	int 10h
	lodsb		
	or al, al	
	jz msgret1
	mov ah, 0xa	
	int 10h		
	inc dl		
	jmp msg_menu3	
;Prints the level 3 msg
msg_menu4:
	mov ah, 0x2	
	int 10h
	lodsb		
	or al, al	
	jz msgret4
	mov ah, 0xa	
	int 10h		
	inc dl		
	jmp msg_menu4	
;Prints the exit  msg
msg_menu5:
	mov ah, 0x2	
	int 10h
	lodsb	
	or al, al
	jz msgret5
	mov ah, 0xa	
	int 10h		
	inc dl		
	jmp msg_menu5	

;Call the level 1 msg from the menu	
wait_for_menu:
	mov	ah, 0x00
	int	0x16
	cmp	al, '1'
	je	start_tetris1
	cmp al, '2'
	je  start_tetris2
	cmp al,  '3'
	je start_tetris3
	;cmp al,  'e'
	;je  start_tetris2
	
	jmp	wait_for_menu
	

	
	
	
	
	
	
	;jmp wait_for_menu

	;jmp	wait_for_menu
%endmacro
	

	

	
; ==============================================================================

speed:      equ 0x7f03
mov word [cte], 0x1

menu

start_tetris1:
	mov word [speed], 4000
	mov byte [level], 0x01
	mov word [points], 0
	je	start_tetris
start_tetris2:
	mov word [speed], 2000
	mov byte [level], 0x02
	mov word [points], 0
	je	start_tetris
start_tetris3:
	mov word [speed], 500
	mov byte [level], 0x03
	mov word [points], 0
	je	start_tetris



section .text

start_tetris:
	delay:      equ 0x7f00
	seed_value: equ 0x7f02
	mov ax, cs
	mov ds, ax   	; Copy CS to DS (we can't do it directly so we use AX temporarily)
	
clear:
	init_screen
	call draw_msg_level

new_brick:
	mov byte [delay], 100            ; 3 * 100 = 300ms
	select_brick                     ; returns the selected brick in AL
	mov dx, start_row_col            ; start at row 4 and col 38
lp:
	call check_collision
	jne  clear                        ; collision -> game over
	call print_brick

wait_or_keyboard:
	xor cx, cx
	mov cl, byte [delay]
	
wait_a:
	push cx
	sleep 3000                       ; wait  speed ms
	
	push ax
	mov ah, 1                    ; check for keystroke; AX modified
	int 0x16                     ; http://www.ctyme.com/intr/rb-1755.htm
	mov cx, ax
	pop ax
	jz no_key                    ; no keystroke
	call clear_brick
                                 ; 4b left, 48 up, 4d right, 50 down
	cmp ch, 0x4b                 ; left arrow
	je left_arrow                ; http://stackoverflow.com/questions/16939449/how-to-detect-arrow-keys-in-assembly
	cmp ch, 0x48                 ; up arrow
	je up_arrow
	cmp ch, 0x4d
	je right_arrow

	
	; Level selection
	;cmp	cl, '5'
	;je	score
	;cmp cl, '2'
	;je  level_two
	;cmp cl,  '3'
	;je  level_three
	;cmp cl,  'e'
	;je  halt

	mov byte [delay], 10         ; every other key is fast down
	jmp clear_keys
left_arrow:
	dec dx
	call check_collision
	je clear_keys                 ; no collision
	inc dx
	jmp clear_keys
right_arrow:
	inc dx
	call check_collision
	je clear_keys                ; no collision
	dec dx
	jmp clear_keys
up_arrow:
	mov bl, al
	inc ax
	inc ax
	test al, 00000111b           ; check for overflow
	jnz nf                       ; no overflow
	sub al, 8
level_one:
	mov word [speed], 4000
	jmp clear_keys
level_two:
	mov word [points], 0x10
	jmp clear_keys
level_three:
	mov word [speed], 500
nf: call check_collision
	je clear_keys                ; no collision
	mov al, bl
clear_keys:
	call print_brick
	push ax
	xor ah, ah                   ; remove key from buffer
	int 0x16
	pop ax
no_key:
	pop cx
	dec ECX
    jnz wait_a

	call clear_brick
	inc dh                       ; increase row
	call check_collision
	je lp                        ; no collision
	dec dh
	call print_brick
	call check_filled
	jmp new_brick

; ------------------------------------------------------------------------------

set_and_write:
	mov ah, 2                    ; set cursor
	int 0x10
	mov ax, 0x0920               ; write boxes
	int 0x10
	ret

set_and_read:
	mov ah, 2                    ; set cursor position
	int 0x10
	mov ah, 8                    ; read character and attribute, BH = 0
	int 0x10                     ; result in AX
	ret

; ------------------------------------------------------------------------------

; DH = current row
%macro replace_current_row 0
	pusha                           ; replace current row with row above
 	mov dl, inner_first_col
 	mov cx, inner_width
cf_aa:
	push cx
	dec dh                          ; decrement row
	call set_and_read
	inc dh                          ; increment row
	mov bl, ah                      ; color from AH to BL
	mov cl, 1
	call set_and_write
	inc dx                          ; next column
	pop cx
	loop cf_aa
	popa
%endmacro

check_filled:
	pusha
	mov dh, 21                  ; start at row 21
next_row:
	dec dh                           ; decrement row
	jz cf_done                       ; at row 0 we are done
	xor bx, bx
	mov cx, inner_width
	mov dl, inner_first_col          ; start at first inner column
cf_loop:
	call set_and_read
	shr ah, 4                        ; rotate to get background color in AH
	jz cf_is_zero                    ; jmp if background color is 0
	inc bx                           ; increment counter
	inc dx                           ; go to next column
cf_is_zero:
	loop cf_loop
	cmp bl, inner_width              ; if counter is 12 full we found a full row
	jne next_row
replace_next_row:                    ; replace current row with rows above
	replace_current_row
	dec dh                           ; replace row above ... and so on
	jnz replace_next_row
	call check_filled                ; check for other full rows
	add word [points], 1
	call update_score   
cf_done:
	popa  
	ret




clear_brick:
	xor bx, bx
	jmp print_brick_no_color
print_brick:  ; al = 0AAAARR0
	mov bl, al                   ; select the right color
	shr bl, 3
	inc bx
	shl bl, 4
print_brick_no_color:
	inc bx                       ; set least significant bit
	mov di, bx
	jmp check_collision_main
	; BL = color of brick
	; DX = position (DH = row), AL = brick offset
	; return: flag
check_collision:
	mov di, 0
check_collision_main:            ; DI = 1 -> check, 0 -> print
	pusha
	xor bx, bx                   ; load the brick into AX
	mov bl, al
	mov ax, word [bricks + bx]

	xor bx, bx                   ; BH = page number, BL = collision counter
	mov cx, 4
cc:
	push cx
	mov cl, 4
zz:
	test ah, 10000000b
	jz is_zero

	push ax
	or di, di
	jz ee                        ; we just want to check for collisions
	pusha                        ; print space with color stored in DI
	mov bx, di                   ; at position in DX
	xor al, al
	mov cx, 1
	call set_and_write
	popa
	jmp is_zero_a
ee:
	call set_and_read
	shr ah, 4                    ; rotate to get background color in AH
	jz is_zero_a                 ; jmp if background color is 0
	inc bx
is_zero_a:
	pop ax

is_zero:
	shl ax, 1                    ; move to next bit in brick mask
	inc dx                       ; move to next column
	loop zz
	sub dl, 4                    ; reset column
	inc dh                       ; move to next row
	pop cx
	loop cc
	or bl, bl                    ; bl != 0 -> collision
	popa
	ret
update_score:
	cmp byte [points], 1
	je points1
	cmp byte [points], 2
	je points2
	cmp byte [points], 3
	je points3
	cmp byte [points], 4
	je points4
	cmp byte [points], 5
	je points5
	cmp byte [points], 6
	je points6
	cmp byte [points], 7
	je points7
	cmp byte [points], 8
	je points8
	cmp byte [points], 9
	je points9
	cmp byte [points], 10
	je points10
	cmp byte [points], 11
	je points11
	cmp byte [points], 12
	je points12
	cmp byte [points], 13
	je points13
	cmp byte [points], 14
	je points14
	cmp byte [points], 15
	je points15
	cmp byte [points], 16
	je points16
	cmp byte [points], 17
	je points17
	cmp byte [points], 18
	je points18
	cmp byte [points], 19
	je points19
	cmp byte [points], 20
	je points20
	
	cmp byte [points], 21
	je points21
	cmp byte [points], 22
	je points22
	cmp byte [points], 23
	je points23
	cmp byte [points], 24
	je points24
	cmp byte [points], 25
	je points25
	cmp byte [points], 26
	je points26
	cmp byte [points], 27
	je points27
	cmp byte [points], 28
	je points28
	cmp byte [points], 29
	je points29
	
	


another_part:
	mov bl, 15   ;White color
	mov bh, 0   
	mov cx, 1	
	mov dh, 0	
	mov dl, 10	
	jmp msg_lvl1


retlvl1:
	ret

points1:
	mov si, lvl11
	jmp another_part 
points2:
	mov si, lvl12
	jmp another_part 
points3:
	mov si, lvl13
	jmp another_part 
points4:
	mov si, lvl14
	jmp another_part 
points5:
	mov si, lvl15
	jmp another_part 
points6:
	mov si, lvl16
	jmp another_part 
points7:
	mov si, lvl17
	jmp another_part 
points8:
	mov si, lvl18
	jmp another_part 
points9:
	mov si, lvl19
	jmp another_part 
points10:
	mov word [speed], 2000
	mov word [points], 10
	mov si, lvl21
	mov byte [level], 0x02
	jmp another_part
points11:
	mov si, lvl21
	jmp another_part
points12:
	mov si, lvl22
	jmp another_part 
points13:
	mov si, lvl23
	jmp another_part 
points14:
	mov si, lvl24
	jmp another_part
points15:
	mov si, lvl25
	jmp another_part 
points16:
	mov si, lvl26
	jmp another_part 
points17:
	mov si, lvl27
	jmp another_part
points18:
	mov si, lvl28
	jmp another_part 
points19:
	mov si, lvl29
	jmp another_part 



points20:
	mov si, lvl3
	mov word [points], 20
	mov byte [level], 0x03
	mov word [speed], 500
	jmp another_part
points21:
	mov si, lvl31
	jmp another_part 
points22:
	mov si, lvl32
	jmp another_part 
points23:
	mov si, lvl33
	jmp another_part
points24:
	mov si, lvl34
	jmp another_part 
points25:
	mov si, lvl35
	jmp another_part
points26:
	mov si, lvl36
	jmp another_part
points27:
	mov si, lvl37
	jmp another_part 
points28:
	mov si, lvl38
	jmp another_part 
points29:
	mov si, lvl39
	jmp another_part 


;Call the level1 msg from the game		
msglvl1:
	mov si, lvl1
	mov bl, 15   ;White color
	mov bh, 0   
	mov cx, 1	
	mov dh, 0	
	mov dl, 10	
	jmp msg_lvl2
;Call the level 2 msg from the menu	
msglvl2:
	;cmp byte [points], 0x10
    ;je points10
	mov si, lvl2
	mov bl, 15   ;White color
	mov bh, 0   
	mov cx, 1	
	mov dh, 0	
	mov dl, 10	
	jmp msg_lvl2
retlvl2:
	ret
;Call the level 3 msg from the menu	
msglvl3:
	;cmp byte [points], 0x20
    ;je points20
	mov si, lvl3
	mov bl, 15   ;White color
	mov bh, 0   
	mov cx, 1	
	mov dh, 0	
	mov dl, 10	
	jmp msg_lvl3
retlvl3:
	ret
	;Prints the level 1 indicator msg
msg_lvl1:
	mov ah, 0x2	
	int 10h
	lodsb		
	or al, al	
	jz retlvl1
	mov ah, 0xa	
	int 10h		
	inc dl		
	jmp msg_lvl1	
;Prints the level 2 msg
msg_lvl2:
	mov ah, 0x2	
	int 10h
	lodsb	
	or al, al	
	jz retlvl2
	mov ah, 0xa	
	int 10h		
	inc dl		
	jmp msg_lvl2	
;Prints the level 3 msg
msg_lvl3:
	mov ah, 0x2	
	int 10h
	lodsb		
	or al, al	
	jz retlvl3
	mov ah, 0xa
	int 10h		
	inc dl		
	jmp msg_lvl3	





;------------------------------In game data-----------------------------	
section .data
	;v_msg	db 'WINNER (press b)', 0
	;go_msg	db 'GAME OVER (press b)', 0
	menu1	dw 'TETRIS', 0
	menu2	dw 'LEVEL 1  (press 1)', 0
	menu3	dw 'LEVEL 2  (press 2)', 0
	menu4	dw 'LEVEL 3  (press 3)', 0
	menu5	dw 'EXIT     (press e)', 0
	lvl1	dw 'Level1     Points : 0', 0
	lvl11	dw 'Level1     Points : 10', 0
	lvl12	dw 'Level1     Points : 20', 0
	lvl13	dw 'Level1     Points : 30', 0
	lvl14	dw 'Level1     Points : 40', 0
	lvl15	dw 'Level1     Points : 50', 0
	lvl16	dw 'Level1     Points : 60', 0
	lvl17	dw 'Level1     Points : 70', 0
	lvl18	dw 'Level1     Points : 80', 0
	lvl19	dw 'Level1     Points : 90', 0

	lvl2	dw 'Level2     Points: 100', 0
	lvl21	dw 'Level2     Points: 110', 0
	lvl22	dw 'Level2     Points: 120', 0
	lvl23	dw 'Level2     Points: 130', 0
	lvl24	dw 'Level2     Points: 140', 0
	lvl25	dw 'Level2     Points: 150', 0
	lvl26	dw 'Level2     Points: 160', 0
	lvl27	dw 'Level2     Points: 170', 0
	lvl28	dw 'Level2     Points: 180', 0
	lvl29	dw 'Level2     Points: 190', 0
	
	lvl3	dw 'Level3     Points: 200', 0
	lvl31	dw 'Level3     Points: 210', 0
	lvl32	dw 'Level3     Points: 220', 0
	lvl33	dw 'Level3     Points: 230', 0
	lvl34	dw 'Level3     Points: 240', 0
	lvl35	dw 'Level3     Points: 250', 0
	lvl36	dw 'Level3     Points: 260', 0
	lvl37	dw 'Level3     Points: 270', 0
	lvl38	dw 'Level3     Points: 280', 0
	lvl39	dw 'Level3     Points: 290', 0
	points 		resw 1
	cte		resw 1
	
	;mov word [points], 0x00

;-----------------------------------------------------------------------

; ==============================================================================
;Shutdown
halt:
	hlt
	ret
; ==============================================================================
;Select the level indicator msg
draw_msg_level:
	cmp byte [level], 0x01
	je msglvl1
	cmp byte [level], 0x02
	je msglvl2
	cmp byte [level], 0x03
	je msglvl3
	
	ret

;Level selection	
level1:
	mov byte [level], 0x01
	jmp	start_tetris

level2:
	mov byte [level], 0x02
	jmp	start_tetris

level3:
	mov byte [level], 0x03
	jmp	start_tetris



;Display the score
print_int: 
	push bp 
	mov bp, sp
	 

;Auxiliar, prepare the int to display
push_digits:
	xor dx, dx
	mov bx, 10 
	div bx 
	push dx 
	test ax, ax 
	jnz push_digits

;Print char by char
pop_and_print_digits:
	pop ax 
	add al, '0' 
	call print_char 
	cmp sp, bp 
	jne pop_and_print_digits 
	pop bp 
	ret

;Print a char 
print_char:
	mov ah, 0x0E 
	mov bh, 0x00 
	mov bl, 0x07 
	int 0x10
	ret


bricks:
	;  in AL      in AH
	;  3rd + 4th  1st + 2nd row
	db 01000100b, 01000100b, 00000000b, 11110000b ; I
	db 01000100b, 01000100b, 00000000b, 11110000b ; I
	db 01100000b, 00100010b, 00000000b, 11100010b ; left L
	db 01000000b, 01100100b, 00000000b, 10001110b ; left L rotate
	db 01100000b, 01000100b, 00000000b, 00101110b ;
	db 00100000b, 01100010b, 00000000b, 11101000b ;
	db 00000000b, 01100110b, 00000000b, 01100110b ;
	db 00000000b, 01100110b, 00000000b, 01100110b ;
	db 00000000b, 11000110b, 01000000b, 00100110b ; 
	db 00000000b, 11000110b, 01000000b, 00100110b ;
	db 00000000b, 01001110b, 01000000b, 01001100b ;
	db 00000000b, 11100100b, 10000000b, 10001100b ;
	db 00000000b, 01101100b, 01000000b, 10001100b ;
	db 00000000b, 01101100b, 01000000b, 10001100b ;

section .bss
	level resb 1