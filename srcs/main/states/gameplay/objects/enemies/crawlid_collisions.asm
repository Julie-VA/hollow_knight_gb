INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "CrawlidCollisions", ROM0

crawlid_check_collision_left::
	; Load x position in b
	ld a, [w_crawlid_position_x_int]
	sub 8 ; -8 Offset grid by 8; +1 Account for blank pixel in sprite; -1 Check incoming tile -> result = -8
	ld b, a

	; Load y position in c
	ld a, [w_crawlid_position_y]
	sub 16 ; Offset grid by 16
	ld c, a

	call check_collision_wall
	or a
	ret nz

	; Check if we're going to walk over a ledge
	; x position already in b

	; Load y position in c
	ld a, [w_crawlid_position_y]
	sub 8 ; -16 Offset grid by 16; +8 Check tile below incoming tile -> result = -8
	ld c, a

	call check_collision_wall
	xor 1 ; Toggle between 0 and 1, if call returns 0 it's a blank tile so we're walking off a ledge
	ret


crawlid_check_collision_right::
	; Load x position in b
	ld a, [w_crawlid_position_x_int]
	dec a; -8 Offset grid by 8; +7 Go to the end of the sprite; -1 Account for blank pixel in sprite; +1 Check incoming tile -> result = -1
	ld b, a

	; Load y position in c
	ld a, [w_crawlid_position_y]
	sub 16 ; Offset grid by 16
	ld c, a

	call check_collision_wall
	or a
	ret nz
	
	; Check if we're going to walk over a ledge
	; x position already in b

	; Load y position in c
	ld a, [w_crawlid_position_y]
	sub 8 ; -16 Offset grid by 16; +8 Check tile below incoming tile -> result = -8
	ld c, a

	call check_collision_wall
	xor 1 ; Toggle between 0 and 1, if call returns 0 it's a blank tile so we're walking off a ledge
	ret


; Crawlid height = 7, Player height = 16, Crawlid length = 13, Player length = 8.
; So for size height: 7/2 + 16/2 = 11, for size ength 13/2 + 8/2 = 10 (-1 to make it bit more forgiving)
crawlid_check_collision_player::
.ld_y_crawlid
	ld a, [w_crawlid_position_y]
	ld [w_object1_value], a

.ld_y_player
	ld a, [w_player_position_y]
	add 6 ; Required because feet are 8 pixels further, only add 6 since crawlid isn't 8 pixels tall
	ld [w_object2_value], a

	ld a, 11
	ld [w_size], a

	call check_object_position_difference

	; If no collision, return
	and a
	ret z

.ld_x_crawlid
	; We need to do a few tweaks depending on the x flip because the crawlid has 1 blank pixels in front and 2 behind.
	ld a, [w_crawlid_position_x_int]
	ld [w_object1_value], a
	ld a, [wShadowOAM + $38 + 3]
	and %00100000 ; Only the x flip bit is useful for this
	cp %00100000
	jr z, :+
	; Turned right
	ld a, [w_object1_value]
	add 4
	ld [w_object1_value], a
	jr .ld_x_player
:
	; Turned left
	ld a, [w_object1_value]
	sub 4
	ld [w_object1_value], a

.ld_x_player
	ld a, [w_player_position_x]
	ld [w_object2_value], a

	ld a, 9
	ld [w_size], a

	call check_object_position_difference

	and a
	ret z

	ld a, [w_player_position_y]
	sub 16
	ld [w_player_position_y], a

	ret


