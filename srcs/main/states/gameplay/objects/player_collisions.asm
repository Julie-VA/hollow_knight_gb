INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "PlayerCollisions", ROM0

; TODO: check collision head
check_collision::
	; 1. Divide x position by 8 to get tile x position
	; 2. Divide y position by 8 to get tile y position -> steps 2 and 3 happen at the same time to avoid unnecessary division/multiplication
	; 3. Multiply tile y position by 32 then add tile x position to get position of tile we're about to run into (has to be done on 16 bit int)
	; 4. Add $98 to high byte to get the tilemap address
	; 5. Get tile number from tilemap address

	ld a, [w_player_position_x]
	sub 8 ; Offset grid
	dec a
	srl a ; Right shift 3 times to divide by 8
	srl a
	srl a
	ld b, a ; Store tile x position in b

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

	; Get tile number from tilemap address
	ld a, [hl]

	cp a, 1
	jr z, .check_collision_hit
	cp a, 2
	jr z, .check_collision_hit

	ld a, 0
	ret

.check_collision_hit
	ld a, 1
	ret
