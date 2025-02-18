INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "PlayerCollisions", ROM0

; We need to check for both bottom and top tile of the sprite
check_collision_left::
	; Load x position in b
	ld a, [w_player_position_x]
	sub 9 ; -8 Offset grid by 8; -1 Check incoming tile -> result = -9
	ld b, a

	; Load y position of bottom tile in c
	ld a, [w_player_position_y]
	dec a ; -16 Offset grid by 16; +15 Check at the feet of player -> result = -1
	ld c, a

	call check_collision_left_right
	or a
	ret nz

	; Load x position in b
	ld a, [w_player_position_x]
	sub 9 ; -8 Offset grid by 8; -1 Check incoming tile -> result = -9
	ld b, a

	; Load y position of top tile in c
	ld a, [w_player_position_y]
	sub 16 ; Offset grid by 16 to check at the head of player
	ld c, a

	call check_collision_left_right
	ret


; We need to check for both bottom and top tile of the sprite
check_collision_right::
	; Load x position in b
	ld a, [w_player_position_x]
	; -8 Offset grid by 8; +7 Go to the end of the sprite; +1 Check incoming tile -> result = 0
	ld b, a

	; Load y position of bottom tile in c
	ld a, [w_player_position_y]
	dec a ; -16 Offset grid by 16; +15 Check at the feet of player -> result = -1
	ld c, a

	call check_collision_left_right
	or a
	ret nz

	; Load x position in b
	ld a, [w_player_position_x]
	; -8 Offset grid by 8; +7 Go to the end of the sprite; +1 Check incoming tile -> result = 0
	ld b, a

	; Load y position of top tile in d
	ld a, [w_player_position_y]
	sub 16 ; Offset grid by 16 to check at the head of player
	ld c, a

	call check_collision_left_right
	ret


check_collision_up::
	; Load x position of left side in b
	ld a, [w_player_position_x]
	sub 8 ; Offset grid by 8
	ld b, a

	; Load x position of right side in c
	ld a, [w_player_position_x]
	dec a ; -8 Offset grid by 8; +7 Go to the end of the sprite -> result = -1
	ld c, a

	; Load y position in d
	ld a, [w_player_position_y]
	sub 17 ; -16 Offset grid by 16; -1 Check incoming tile -> result = -17
	ld d, a

	call check_collision_up_down
	ret


check_collision_down::
	; Load x position of left side in b
	ld a, [w_player_position_x]
	sub 6 ; -8 Offset grid by 8; +2 Check at back foot of sprite -> result = -6
	ld b, a

	; Load x position of right side in c
	ld a, [w_player_position_x]
	sub 3 ; +8 Offset grid by 8; +5 Go to back foot of sprite from right side -> result = -3
	ld c, a

	; Load y position in d
	ld a, [w_player_position_y]
	; -16 Offset grid by 16; +8 Check at the feet of player; +7 Go to the end of the sprite; +1 Check incoming tile -> result = 0
	ld d, a

	call check_collision_up_down
	ret


; @param b: X position of left side of sprite
; @param c: X position of right side of sprite
; @param d: Y position
; Parameters are set by each direction function
; 1: Divide x position by 8 to get tile x position
; 2 (intuitive approach): Divide y position by 8 to get tile y position + Multiply tile y position by 32 then add tile x position to get position of the bg tile we're about to run into
; 2 (implemented): Set last 3 bits of y position to 0 (same as dividing since we multiply after), and multiply by 4 to get tile y position. Then add tile x position
; 3: Add $98 to high byte to get the tilemap address
; 4: Get tile number from tilemap address
check_collision_up_down:
	; Load x position in a
	ld a, b

	; Right shift 3 times to divide by 8 to get tile x position
	srl a
	srl a
	srl a
	ld e, a ; Store tile x position in e

	; Load y position of bottom tile in a
	ld a, d

	; Set the lower 3 bits to 0
	and a, ~7 ; = and a, ~00000111 = and a, 11111000

	; Multiply y position by 4 to get tile y position
	ld h, 0
	ld l, a
	add hl, hl
	add hl, hl

	; Add tile x position to get the full index
	ld a, l
	add e
	ld l, a

	; Add $98 to high byte h to get address from tilemap
	ld a, h
	add a, $98
	ld h, a

	; Get tile number from tilemap address
	ld a, [hl]

	; Check collision
	or a
	jr nz, .check_collision_up_down_hit

	; Check if we have already checked collision for right side
	ld a, c
	cp 255
	jr z, .check_collision_up_down_no_hit
	; If we haven't, place right side x position in b and execute check_collision_up_down again
	ld b, c
	ld c, 255
	jr check_collision_up_down

.check_collision_up_down_no_hit
	xor a
	ret

.check_collision_up_down_hit
	ld a, 1
	ret
