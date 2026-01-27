INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"
INCLUDE "srcs/main/utils/oam_number_table.inc"

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
	ret


crawlid_check_collision_rear_left::
	; Load x position in b
	ld a, [w_crawlid_position_x_int]
	sub 15 ; -8 Offset grid by 8; -8 Check the rear of crawlid; +2 Account for blank pixels in sprite; -1 Check incoming tile -> result = -15
	ld b, a

	; Load y position in c
	ld a, [w_crawlid_position_y]
	sub 16 ; Offset grid by 16
	ld c, a

	call check_collision_wall
	ret


crawlid_check_collision_rear_right::
	; Load x position in b
	ld a, [w_crawlid_position_x_int]
	add 6 ; -8 Offset grid by 8; +15 Check the rear of crawlid; -2 Account for blank pixels in sprite; +1 Check incoming tile -> result = +6
	ld b, a

	; Load y position in c
	ld a, [w_crawlid_position_y]
	sub 16 ; Offset grid by 16
	ld c, a

	call check_collision_wall
	ret


crawlid_check_ledge_left::
	; Load x position in b
	ld a, [w_crawlid_position_x_int]
	sub 8 ; -8 Offset grid by 8; +1 Account for blank pixel in sprite; -1 Check incoming tile -> result = -8
	ld b, a

	; Load y position in c
	ld a, [w_crawlid_position_y]
	sub 8 ; -16 Offset grid by 16; +8 Check tile below incoming tile -> result = -8
	ld c, a

	call check_collision_wall
	xor 1 ; If call returns 0 change it to 1, it's a blank tile so we're walking off a ledge
	ret


crawlid_check_ledge_right::
	; Load x position in b
	ld a, [w_crawlid_position_x_int]
	dec a; -8 Offset grid by 8; +7 Go to the end of the sprite; -1 Account for blank pixel in sprite; +1 Check incoming tile -> result = -1
	ld b, a

	; Load y position in c
	ld a, [w_crawlid_position_y]
	sub 8 ; -16 Offset grid by 16; +8 Check tile below incoming tile -> result = -8
	ld c, a

	call check_collision_wall
	xor 1 ; If call returns 0 change it to 1, it's a blank tile so we're walking off a ledge
	ret


crawlid_check_collision_down::
	; Load x position in b
	ld a, [w_crawlid_position_x_int]
	sub 2; -8 Offset grid by 8; +7 Go to the end of the sprite; -1 Account for blank pixel in sprite -> result = -2
	ld b, a

	; Load y position in c
	ld a, [w_crawlid_position_y]
	sub 8 ; Offset grid by 16; +7 Go to the end of the sprite; +1 Check incoming tile -> result = -8
	ld c, a

	call check_collision_wall
	ret


; Crawlid height = 7, Player height = 16, Crawlid length = 13, Player length = 8.
; So for size height: 7/2 + 16/2 = 11, for size length 13/2 + 8/2 = 10 (-1 to make it bit more forgiving)
crawlid_check_player_collision::
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
	ld a, [wShadowOAM + OAM_CRAWLID_L + 3]
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

	; If no collision, return
	and a
	ret z

	; If we get here, this means there is a collision
	; Check if crawlid is on the left or right side of player to know in which direction they should be sent
	ld a, [w_player_position_x]
	ld b, a
	ld a, [w_crawlid_position_x_int]
	cp b
	jr c, :+
	; Player pos <= crawlid pos, player gets hit on the right side
	ld a, 1
	ld [w_player_hit_side], a
	call handle_player_hit
	ret
:
	; Player pos > crawlid pos, player gets hit on the left side
	xor a
	ld [w_player_hit_side], a
	call handle_player_hit
	ret


; Crawlid height = 7, Slash height = 16, Crawlid length = 13, Slash length = 16
; So for size height: 7/2 + 16/2 = 11, for size length 13/2 + 16/2 = 15 (+1 to make it bit more forgiving)
crawlid_check_slash_collision::
.ld_y_crawlid
	ld a, [w_crawlid_position_y]
	; add 4
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

	ld a, 12
	ld [w_size], a

	call check_object_position_difference

	; If no collision, return
	and a
	ret z

.ld_x_crawlid
	; We need to do a few tweaks depending on the x flip because the crawlid has 1 blank pixels in front and 2 behind.
	ld a, [w_crawlid_position_x_int]
	ld [w_object1_value], a
	ld a, [wShadowOAM + OAM_CRAWLID_L + 3]
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

	ld a, 16
	ld [w_size], a

	call check_object_position_difference

	; If no collision, return
	and a
	ret z

	; If we get here, this means there is a collision
	; Check if crawlid is on the left or right side of player to know in which direction it should be sent
	ld a, [w_player_position_x]
	ld b, a
	ld a, [w_crawlid_position_x_int]
	cp b
	jr c, :+
	; Player pos <= crawlid pos, crawlid gets hit on the left side
	ld a, 1
	ld [w_crawlid_hit_side], a
	call crawlid_hit
	ret
:
	; Player pos > crawlid pos, player gets hit on the right side
	xor a
	ld [w_crawlid_hit_side], a
	call crawlid_hit
	ret
