INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "CrawlidCollisions", ROM0

crawlid_check_collision_left::
	; Load x position in b
	ld a, [w_enemy_1_position_x_int]
	sub 8 ; -8 Offset grid by 8; +1 Account for blank pixel in sprite; -1 Check incoming tile -> result = -8
	ld b, a

	; Load y position of bottom tile in c
	ld a, [w_enemy_1_position_y]
	sub 16 ; Offset grid by 16
	ld c, a

	call check_collision_left_right
	or a
	ret nz

	; Check if we're going to walk over a ledge
	; Load x position in b
	ld a, [w_enemy_1_position_x_int]
	sub 8 ; -8 Offset grid by 8; +1 Account for blank pixel in sprite; -1 Check incoming tile -> result = -8
	ld b, a

	; Load y position of bottom tile in c
	ld a, [w_enemy_1_position_y]
	sub 8 ; -16 Offset grid by 16; +8 Check tile below incoming tile -> result = -8
	ld c, a

	call check_collision_left_right
	xor 1 ; Toggle between 0 and 1, if call returns 0 it's a blank tile so we're walking off a ledge

	ret


crawlid_check_collision_right::
	; Load x position in b
	ld a, [w_enemy_1_position_x_int]
	dec a; -8 Offset grid by 8; +7 Go to the end of the sprite; -1 Account for blank pixel in sprite; +1 Check incoming tile -> result = -1
	ld b, a

	; Load y position of bottom tile in c
	ld a, [w_enemy_1_position_y]
	sub 16 ; Offset grid by 16
	ld c, a

	call check_collision_left_right
	or a
	ret nz
	
	; Check if we're going to walk over a ledge
	; Load x position in b
	ld a, [w_enemy_1_position_x_int]
	dec a; -8 Offset grid by 8; +7 Go to the end of the sprite; -1 Account for blank pixel in sprite; +1 Check incoming tile -> result = -1
	ld b, a

	; Load y position of bottom tile in c
	ld a, [w_enemy_1_position_y]
	sub 8 ; -16 Offset grid by 16; +8 Check tile below incoming tile -> result = -8
	ld c, a

	call check_collision_left_right
	xor 1 ; Toggle between 0 and 1, if call returns 0 it's a blank tile so we're walking off a ledge

	ret
