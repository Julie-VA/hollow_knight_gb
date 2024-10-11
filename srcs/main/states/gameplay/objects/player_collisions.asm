INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "PlayerCollisions", ROM0

check_collision_left::
	ld a, [w_player_position_x]
	sub 8 ; Offset grid
	dec a ; Check tile at the position we're going

	call check_collision
	ret


check_collision_right::
	ld a, [w_player_position_x]
	; Offset grid by 8, add 7 to go to the end of the sprite and add 1 to check incoming tile -> result = 0

	call check_collision
	ret


; 1. Divide x position by 8 to get tile x position
; 2. Divide y position by 8 to get tile y position + Multiply tile y position by 32 then add tile x position to get position of tile we're about to run into
; -> this step is done by setting the last 3 bits of the y position to 0, effectively truncating the position like if we had divided it by 8. We can then multiply
; it by 4 and achieve the same result as the intuitive approach
; 3. Add $98 to high byte to get the tilemap address
; 4. Get tile number from tilemap address
check_collision:
	srl a ; Right shift 3 times to divide by 8
	srl a
	srl a
	ld b, a ; Store tile x position in b

; Place tile number of incoming tile in d
.check_collision_bottom
	ld a, [w_player_position_y]
	sub 8 ; Offset grid by 16 but add 8 to check at the feet of player
	and a, ~7 ; = and a, ~00000111 = and a, 11111000 -> goal is to set the lower 3 bits to 0 without changing the upper 5

	; Multiply y position by 4 to get 
	ld h, 0
	ld l, a
	add hl, hl
	add hl, hl

	; Add tile x position to get the full index
	ld a, l
	add b
	ld l, a

	; Add $98 to get address from tilemap
	ld a, h
	add a, $98
	ld h, a

	; Store tile number from tilemap address in d
	ld a, [hl]
	ld d, a

; Place tile number of incoming tile in e
.check_collision_top
	ld a, [w_player_position_y]
	sub 16 ; Offset grid by 16 to check at the head of player
	and a, ~7 ; = and a, ~00000111 = and a, 11111000 -> goal is to set the lower 3 bits to 0 without changing the upper 5

	ld h, 0
	ld l, a
	add hl, hl
	add hl, hl

	; Add tile x position to get the full index
	ld a, l
	add b
	ld l, a

	; Add $98 to get address from tilemap
	ld a, h
	add a, $98
	ld h, a

	; Store tile number from tilemap address in e
	ld a, [hl]
	ld e, a

.check_collision_end
	; Get tile number from tilemap address bottom
	ld a, d
	; Check bottom collision
	or 0
	jr nz, .check_collision_hit

	; Get tile number from tilemap address top
	ld a, e
	; Check top collision
	or 0
	jr nz, .check_collision_hit

	ld a, 0
	ret

.check_collision_hit
	ld a, 1
	ret


check_collision_ground::
	ld a, [w_player_position_x]
	sub 8 ; Offset grid

	srl a ; Right shift 3 times to divide by 8
	srl a
	srl a
	ld b, a ; Store tile x position in b

	ld a, [w_player_position_y]
	; Offset grid by 16, add 8 to check at the feet of player, add 7 to go to the end of the sprite and add 1 to check incoming tile -> result = 0
	and a, ~7 ; = and a, ~00000111 = and a, 11111000 -> goal is to set the lower 3 bits to 0 without changing the upper 5

	ld h, 0
	ld l, a
	add hl, hl
	add hl, hl

	; Add tile x position to get the full index
	ld a, l
	add b
	ld l, a

	; Add $98 to get address from tilemap
	ld a, h
	add a, $98
	ld h, a

	; Get tile number from tilemap address
	ld a, [hl]

	; Check collision
	or 0
	jr nz, .check_collision_ground_hit

	ret

.check_collision_ground_hit
	ret