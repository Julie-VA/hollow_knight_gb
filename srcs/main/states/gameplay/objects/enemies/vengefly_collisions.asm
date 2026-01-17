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

	call check_collision_wall
	or a
	ret nz

	; x position already in b

	; Load y position of top tile in c
	ld a, [w_vengefly_position_y]
	sub 10 ; -16 Offset grid by 16; +6 Account for blank pixels in sprite -> result = -10
	ld c, a

	call check_collision_wall
	ret


vengefly_check_collision_right::
	; Load x position in b
	ld a, [w_vengefly_position_x_int]
	; -8 Offset grid by 8; +7 Go to the end of sprite; +1 Check incoming tile -> result = 0
	ld b, a

	; Load y position of bottom tile in c
	ld a, [w_vengefly_position_y]
	dec a ; -16 Offset grid by 16; +15 Check at the bottom of vengefly -> result = -1
	ld c, a

	call check_collision_wall
	or a
	ret nz

	; x position already in b

	; Load y position of top tile in c
	ld a, [w_vengefly_position_y]
	sub 10 ; -16 Offset grid by 16; +6 Account for blank pixels in sprite -> result = -10
	ld c, a

	call check_collision_wall
	ret


vengefly_check_collision_up::
	; Load y position in c
	ld a, [w_vengefly_position_y]
	sub 11 ; -16 Offset grid by 16; +6 Account for blank pixels in sprite; -1 Check incoming tile -> result = -11
	ld c, a

	; Check x flip of sprite
	ld a, [wShadowOAM + $4C + 3]
	or a
	jr nz, .flipped_right

.flipped_left
	; Load x position of left side in b
	ld a, [w_vengefly_position_x_int]
	sub 8 ; Offset grid by 8
	ld b, a
	; y position already in c
	call check_collision_wall
	or a
	ret nz

	; Load x position of right side in b
	ld a, [w_vengefly_position_x_int]
	add 5 ; -8 Offset grid by 8; +15 Go to the end of the sprite; -2 Account for blank pixels in sprite -> result = +5
	ld b, a
	; y position already in c
	call check_collision_wall
	ret

.flipped_right
	; Load x position of left side in b
	ld a, [w_vengefly_position_x_int]
	sub 14 ; -8 Offset grid by 8; -8 Go to the end of the sprite; +2 Account for blank pixels in sprite -> result = -14
	ld b, a
	; y position already in c
	call check_collision_wall
	or a
	ret nz

	; Load x position of right side in b
	ld a, [w_vengefly_position_x_int]
	sub 1 ; -8 Offset grid by 8; +7 Go to the end of the sprite; -> result = -1
	ld b, a
	; y position already in c
	call check_collision_wall
	ret


vengefly_check_collision_down::
	; Load y position in c
	ld a, [w_vengefly_position_y]
	; -16 Offset grid by 16; +15 Go to the end of sprite; +1 Check incoming tile -> result = 0
	ld c, a

	; Check x flip of sprite
	ld a, [wShadowOAM + $4C + 3]
	or a
	jr nz, .flipped_right

.flipped_left
	; Load x position of left side in b
	ld a, [w_vengefly_position_x_int]
	sub 8 ; Offset grid by 8
	ld b, a
	; y position already in c
	call check_collision_wall
	or a
	ret nz

	; Load x position of right side in b
	ld a, [w_vengefly_position_x_int]
	add 5 ; -8 Offset grid by 8; +15 Go to the end of the sprite; -2 Account for blank pixels in sprite -> result = +5
	ld b, a
	; y position already in c
	call check_collision_wall
	ret

.flipped_right
	; Load x position of left side in b
	ld a, [w_vengefly_position_x_int]
	sub 14 ; -8 Offset grid by 8; -8 Go to the end of the sprite; +2 Account for blank pixels in sprite -> result = -14
	ld b, a
	; y position already in c
	call check_collision_wall
	or a
	ret nz

	; Load x position of right side in b
	ld a, [w_vengefly_position_x_int]
	sub 1 ; -8 Offset grid by 8; +7 Go to the end of the sprite; -> result = -1
	ld b, a
	; y position already in c
	call check_collision_wall
	ret
