INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "PlayerCollisions", ROM0

; We need to check for both bottom and top tile of the sprite
check_wall_collision_left::
	; Load x position in b
	ld a, [w_player_position_x]
	sub 9 ; -8 Offset grid by 8; -1 Check incoming tile -> result = -9
	ld b, a

	; Load y position of bottom tile in c
	ld a, [w_player_position_y]
	dec a ; -16 Offset grid by 16; +15 Check at the feet of player -> result = -1
	ld c, a

	call check_collision_wall
	or a
	ret nz

	; x position already in b

	; Load y position of top tile in c
	ld a, [w_player_position_y]
	sub 16 ; Offset grid by 16 to check at the head of player
	ld c, a

	call check_collision_wall
	ret


; We need to check for both bottom and top tile of the sprite
check_wall_collision_right::
	; Load x position in b
	ld a, [w_player_position_x]
	; -8 Offset grid by 8; +7 Go to the end of the sprite; +1 Check incoming tile -> result = 0
	ld b, a

	; Load y position of bottom tile in c
	ld a, [w_player_position_y]
	dec a ; -16 Offset grid by 16; +15 Check at the feet of player -> result = -1
	ld c, a

	call check_collision_wall
	or a
	ret nz

	; x position already in b

	; Load y position of top tile in c
	ld a, [w_player_position_y]
	sub 16 ; Offset grid by 16 to check at the head of player
	ld c, a

	call check_collision_wall
	ret


check_wall_collision_up::
	; Load x position of left side in b
	ld a, [w_player_position_x]
	sub 8 ; Offset grid by 8
	ld b, a

	; Load y position in c
	ld a, [w_player_position_y]
	sub 17 ; -16 Offset grid by 16; -1 Check incoming tile -> result = -17
	ld c, a

	call check_collision_wall
	or a
	ret nz

	; Load x position of right side in b
	ld a, [w_player_position_x]
	dec a ; -8 Offset grid by 8; +7 Go to the end of the sprite -> result = -1
	ld b, a

	; y position already in c

	call check_collision_wall
	ret


check_wall_collision_down::
	; Load x position of left side in b
	ld a, [w_player_position_x]
	sub 6 ; -8 Offset grid by 8; +2 Check at back foot of sprite -> result = -6
	ld b, a

	; Load y position in c
	ld a, [w_player_position_y]
	; -16 Offset grid by 16; +8 Check at the feet of player; +7 Go to the end of the sprite; +1 Check incoming tile -> result = 0
	ld c, a

	call check_collision_wall
	or a
	ret nz

	; Load x position of right side in b
	ld a, [w_player_position_x]
	sub 3 ; +8 Offset grid by 8; +5 Go to back foot of sprite from right side -> result = -3
	ld b, a

	; y position already in c

	call check_collision_wall
	ret
