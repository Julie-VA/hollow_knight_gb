INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"
INCLUDE "srcs/main/utils/oam_number_table.inc"

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
	ld a, [wShadowOAM + OAM_VENGEFLY_TL + 3]
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
	ld a, [wShadowOAM + OAM_VENGEFLY_TL + 3]
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


; Vengefly height = 10, Player height = 16, Vengefly length = 14, Player length = 8.
; So for size height: 10/2 + 16/2 = 13 (-2 to make it bit more forgiving), for size length 14/2 + 8/2 = 11 (-1 to make it bit more forgiving)
vengefly_check_player_collision::
.ld_y_vengefly
	ld a, [w_vengefly_position_y]
	add 3
	ld [w_object1_value], a

.ld_y_player
	ld a, [w_player_position_y]
	ld [w_object2_value], a

	ld a, 11
	ld [w_size], a

	call check_object_position_difference

	; If no collision, return
	and a
	ret z

.ld_x_vengefly
	; We need to do a few tweaks depending on the x flip because the vengefly has no blank pixel in front and 2 behind.
	ld a, [w_vengefly_position_x_int]
	ld [w_object1_value], a
	ld a, [wShadowOAM + OAM_VENGEFLY_TL + 3]
	and %00100000 ; Only the x flip bit is useful for this
	cp %00100000
	jr z, :+
	; Turned left
	ld a, [w_object1_value]
	add 2
	ld [w_object1_value], a
	jr .ld_x_player
:
	; Turned right
	ld a, [w_object1_value]
	sub 2
	ld [w_object1_value], a

.ld_x_player
	ld a, [w_player_position_x]
	ld [w_object2_value], a

	ld a, 10
	ld [w_size], a

	call check_object_position_difference

	; If no collision, return
	and a
	ret z

	; If we get here, this means there is a collision
	; Check if vengefly is on the left or right side of player to know in which direction they should be sent
	ld a, [w_player_position_x]
	ld b, a
	ld a, [w_vengefly_position_x_int]
	cp b
	jr c, :+
	; Player pos <= vengefly pos, player gets hit on the right side
	ld a, 1
	ld [w_player_hit_side], a
	call handle_player_hit
	ret
:
	; Player pos > vengefly pos, player gets hit on the left side
	xor a
	ld [w_player_hit_side], a
	call handle_player_hit
	ret


; Vengefly height = 10, Slash height = 16, Vengefly length = 14, Slash length = 16
; So for size height: 10/2 + 16/2 = 13, for size length 14/2 + 16/2 = 15 (+1 to make it bit more forgiving)
vengefly_check_slash_collision::
.ld_y_vengefly
	ld a, [w_vengefly_position_y]
	add 10
	ld [w_object1_value], a

.ld_y_player
	; If player is attacking left or right (w_player_attacking == 1 or 2), do not change the y position, change it if they're attacking up or down
	ld a, [w_player_attacking]
	cp 3
	ld a, [w_player_position_y] ; Loading the position cause we'll need it for every case
	jr c, :++ ; Attacking left or right
	jr z, :+; Attacking up
	add 16 ; Attacking down
	jr :++
:
	sub 16 ; Attacking up
:
	add 8 ; Go down to middle of attack, the previous operations were 16 to account for this
	ld [w_object2_value], a

	ld a, 11
	ld [w_size], a

	call check_object_position_difference

	; If no collision, return
	and a
	ret z

.ld_x_vengefly
	; We need to do a few tweaks depending on the x flip because the vengefly has 0 blank pixel in front and 2 behind.
	ld a, [w_vengefly_position_x_int]
	ld [w_object1_value], a
	ld a, [wShadowOAM + OAM_VENGEFLY_TL + 3]
	and %00100000 ; Only the x flip bit is useful for this
	cp %00100000
	jr z, :+
	; Turned left
	ld a, [w_object1_value]
	add 2
	ld [w_object1_value], a
	jr .ld_x_player
:
	; Turned right
	ld a, [w_object1_value]
	sub 4
	ld [w_object1_value], a

.ld_x_player
	; If player is attacking up or down (w_player_attacking == 3 or 4), do not change the x position, change it if they're attacking left or right
	ld a, [w_player_attacking]
	cp 3
	ld a, [w_player_position_x] ; Restore position in a
	jr nc, :++ ; Attacking up or down

	ld a, [w_player_attacking]
	cp 2
	jr z, :+ ; Attacking left
	ld a, [w_player_position_x]
	add 8 ; Attacking right
	jr :++
:
	ld a, [w_player_position_x]
	sub 8 ; Attacking left
:
	ld [w_object2_value], a

	ld a, 17
	ld [w_size], a

	call check_object_position_difference

	; If no collision, return
	and a
	ret z

	; If we get here, this means there is a collision
	; Check if vengefly is on the left or right side of player to know in which direction it should be sent
	ld a, [w_player_position_x]
	ld b, a
	ld a, [w_vengefly_position_x_int]
	cp b
	jr c, :+
	; Player pos <= vengefly pos, vengefly gets hit on the left side
	ld a, 1
	ld [w_vengefly_hit_side], a
	call vengefly_hit
	ret
:
	; Player pos > vengefly pos, player gets hit on the right side
	xor a
	ld [w_vengefly_hit_side], a
	call vengefly_hit
	ret
