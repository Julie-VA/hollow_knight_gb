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
	sub 8 ; Offset grid
	inc a ; Check tile at the position we're going
	add 7 ; Add 7 to go to the end of the sprite

	call check_collision
	ret


check_collision:
	; 1. Divide x position by 8 to get tile x position
	; 2. Divide y position by 8 to get tile y position -> steps 2 and 3 happen at the same time to avoid unnecessary division/multiplication
	; 3. Multiply tile y position by 32 then add tile x position to get position of tile we're about to run into (has to be done on 16 bit int)
	; 4. Add $98 to high byte to get the tilemap address
	; 5. Get tile number from tilemap address

	srl a ; Right shift 3 times to divide by 8
	srl a
	srl a
	ld b, a ; Store tile x position in b

; Place tilemap address of incoming tile in hl
.check_collision_bottom
	ld a, [w_player_position_y]
	sub 8 ; Offset grid by 16 but add 8 to check at the feet of player
	ld h, 0
	ld l, a
    sla l ; Left shift 16 bit int 2 times to multiply by 4 (same as dividing by 8 first to get tile y position, then multiplying by 32 to get tile index)
	rl h
	sla l
	rl h

	; Add tile x position to get the full index
	ld a, l
	add b
	ld l, a

	; Add $98 to get address from tilemap
	ld a, h
	add a, $98
	ld h, a

; Place tilemap address of incoming tile in de
.check_collision_top
	ld a, [w_player_position_y]
	sub 16 ; Offset grid by 16 to check at the head of player
	ld d, 0
	ld e, a
    sla e ; Left shift 16 bit int 2 times to multiply by 4 (same as dividing by 8 first to get tile y position, then multiplying by 32 to get tile index)
	rl d
	sla e
	rl d

	; Add tile x position to get the full index
	ld a, e
	add b
	ld e, a

	; Add $98 to get address from tilemap
	ld a, d
	add a, $98
	ld d, a

.check_collision_end
	; Get tile number from tilemap address bottom
	ld a, [hl]

	; Check bottom collision
	cp a, 1
	jr z, .check_collision_hit
	cp a, 2
	jr z, .check_collision_hit
	cp a, 3
	jr z, .check_collision_hit

	; Get tile number from tilemap address top
	ld a, [de]

	; Check top collision
	cp a, 1
	jr z, .check_collision_hit
	cp a, 2
	jr z, .check_collision_hit
	cp a, 3
	jr z, .check_collision_hit

	ld a, 0
	ret

.check_collision_hit
	ld a, 1
	ret
