INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "VengeflyCollisions", ROM0

vengefly_check_collision_left::
	; Load x position in b
	ld a, [w_vengefly_position_x_int]
	sub 9 ; -8 Offset grid by 8; -1 Check incoming tile -> result = -9
	ld b, a

	; Load y position of bottom tile in c
	ld a, [w_vengefly_position_y]
	dec a ; -16 Offset grid by 16; +15 Check at the bottom of vengefly -> result = -1
	ld c, a

	call check_collision_left_right
	or a
	ret nz

	; Load x position in b
	ld a, [w_vengefly_position_x_int]
	sub 9 ; -8 Offset grid by 8; -1 Check incoming tile -> result = -9
	ld b, a

	; Load y position of top tile in c
	ld a, [w_vengefly_position_y]
	sub 16 ; Offset grid by 16 to check at the top of vengefly
	ld c, a

	call check_collision_left_right

	ret


vengefly_check_collision_right::
	; Load x position in b
	ld a, [w_vengefly_position_x_int]
	sub 8 ; -8 Offset grid by 8; +15 Go to the end of the sprite; +1 Check incoming tile -> result = -8
	ld b, a

	; Load y position of bottom tile in c
	ld a, [w_vengefly_position_y]
	dec a ; -16 Offset grid by 16; +15 Check at the bottom of vengefly -> result = -1
	ld c, a

	call check_collision_left_right
	or a
	ret nz

	; Load x position in b
	ld a, [w_vengefly_position_x_int]
	sub 8 ; -8 Offset grid by 8; +15 Go to the end of the sprite; +1 Check incoming tile -> result = -8
	ld b, a

	; Load y position of top tile in d
	ld a, [w_vengefly_position_y]
	sub 16 ; Offset grid by 16 to check at the top of vengefly
	ld c, a

	call check_collision_left_right
	ret
