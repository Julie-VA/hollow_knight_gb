INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "VengeflyVariables", WRAM0

; The vengefly's position always reflects the top left pixel of the top left sprite. So when the sprite is flipped, the position is now at the top left pixel of the top right sprite (+8).
w_vengefly_active::			db
w_vengefly_position_x_int::	db
w_vengefly_position_x_dec::	db
w_vengefly_position_y::		db
w_vengefly_type::			db
w_vengefly_health::			db

w_vengefly_direction::		db ; 0 = left, 1 = right, 2 = up, 3 = down
w_vengefly_counter::		db


SECTION "Vengefly", ROM0

initialize_vengefly::
	xor a
	ld [w_vengefly_direction], a
	ld a, VENGEFLY_IDLE_WAIT_LENGTH
	ld [w_vengefly_counter], a

	; Set active_byte
	ld a, 1
	ld [w_vengefly_active], a
	; Set y_byte
	; ld a, 32
	ld a, 26
	ld [w_vengefly_position_y], a
	; Set x_byte
	ld a, 48
	; ld a, 64
	ld [w_vengefly_position_x_int], a
	xor a
	ld [w_vengefly_position_x_dec], a
	; Set type_byte
	ld a, VENGEFLY
	ld [w_vengefly_type], a
	; Set health_byte
	ld a, VENGEFLY_HEALTH
	ld [w_vengefly_health], a

	; Set vengefly_ul
	ld a, [w_vengefly_position_y]
	ld b, a
	ld a, [w_vengefly_position_x_int]
	ld c, a
	ld d, $12
	ld e, 0
	call RenderSimpleSprite

	; Set vengefly_ur
	ld a, [w_vengefly_position_y]
	ld b, a
	ld a, [w_vengefly_position_x_int]
	add 8
	ld c, a
	ld d, $13
	ld e, 0
	call RenderSimpleSprite

	; Set vengefly_dl
	ld a, [w_vengefly_position_y]
	add 8
	ld b, a
	ld a, [w_vengefly_position_x_int]
	ld c, a
	ld d, $14
	ld e, 0
	call RenderSimpleSprite

	; Set vengefly_dr
	ld a, [w_vengefly_position_y]
	add 8
	ld b, a
	ld a, [w_vengefly_position_x_int]
	add 8
	ld c, a
	ld d, $15
	ld e, 0
	call RenderSimpleSprite

	ret


update_vengefly::
	call vengefly_ai
	call draw_vengefly
	ret


vengefly_ai:
	; Check if player is within VENGEFLY_RADIUS
	ld a, [w_player_position_x]
	ld hl, w_vengefly_position_x_int
	sub [hl]
	jr nc, .vengefly_ai_absolute_x ; If no carry, difference is already positive
	cpl ; Else, invert bits and add 1 to get absolute value
	inc a
.vengefly_ai_absolute_x
	cp VENGEFLY_RADIUS
	jr nc, vengefly_ai_idle

	ld a, [w_player_position_y]
	ld hl, w_vengefly_position_y
	sub [hl]
	jr nc, .vengefly_ai_absolute_y
	cpl
	inc a
.vengefly_ai_absolute_y
	cp VENGEFLY_RADIUS
	jr nc, vengefly_ai_idle

	; If we reach here, that means the player is within the radius
	jr vengefly_ai_target_player
	ret


vengefly_ai_target_player:
	; Increment decimal
	ld a, [w_vengefly_position_x_dec]
	add THREE_PIXELS_EVERY_7F
	ld [w_vengefly_position_x_dec], a
	; Increment integer if carry
	ret nc

.check_x
	ld a, [w_vengefly_position_x_int]
	ld hl, w_player_position_x

	cp [hl] ; Compare vengefly and player x positions
	jr z, .check_y ; If equal, check y movement
	call nc, vengefly_ai_move.left ; If vengefly X > player X, move left
	call c, vengefly_ai_move.right ; If vengefly X < player X, move right

.check_y
	ld a, [w_vengefly_position_y]
	ld hl, w_player_position_y

	cp [hl] ; Compare vengefly and player y positions
	ret z ; If equal, ret
	call nc, vengefly_ai_move.up ; If vengefly Y > player Y, move up
	call c, vengefly_ai_move.down ; If vengefly Y < player Y, move down
	ret


; If the player is outside the radius, the vengefly will randomly move a little in one of the 4 directions and stop in between each movement
vengefly_ai_idle:
	; Check if we should wait or move
	ld a, [w_vengefly_counter]
	cp VENGEFLY_IDLE_MOV_LENGTH
	jr c, .vengefly_ai_idle_move ; If counter < VENGEFLY_IDLE_MOV_LENGTH, move

	; Increment counter
	ld a, [w_vengefly_counter]
	inc a
	ld [w_vengefly_counter], a
	; Else, wait before resetting counter and moving again
	cp VENGEFLY_IDLE_WAIT_LENGTH
	ret c

	xor a
	ld [w_vengefly_counter], a

	; Generate new direction with pseudo random number
	call rand
	and %00000011 ; Only keep last 2 bits since we want 4 options
	ld [w_vengefly_direction], a

.vengefly_ai_idle_move
	; Increment decimal
	ld a, [w_vengefly_position_x_dec]
	add ONE_PIXEL_EVERY_4F
	ld [w_vengefly_position_x_dec], a
	; Increment integer if carry
	ret nc

	; Increment counter
	ld a, [w_vengefly_counter]
	inc a
	ld [w_vengefly_counter], a

	; Go to right code depending on direction
	ld a, [w_vengefly_direction]
	or a
	jr z, vengefly_ai_move.left
	cp 1
	jr z, vengefly_ai_move.right
	cp 2
	jr z, vengefly_ai_move.up
	cp 3
	jr z, vengefly_ai_move.down


vengefly_ai_move:
.left
	call vengefly_check_collision_left
	; If we're going to hit a solid tile, don't move
	or a
	ret nz

	; Check x flip of sprite
	ld a, [wShadowOAM + $4C + 3]
	or a
	jr z, :++

	; Check if we're past half the player before turning around. Necessary since we're updating the position after flipping, the sprite is 16p wide and no security would make vengefly turn around constantly when going straight up or down on player
	ld a, [w_vengefly_position_x_int]
	ld hl, w_player_position_x
	sub [hl]
	jr nc, :+
	cpl
	inc a
	:cp 5
	jr c, :+

	; If flipped, set to no flip
	xor a
	ld [wShadowOAM + $40 + 3], a
	ld [wShadowOAM + $44 + 3], a
	ld [wShadowOAM + $48 + 3], a
	ld [wShadowOAM + $4C + 3], a

	:ld a, [w_vengefly_position_x_int]
	dec a
	ld [w_vengefly_position_x_int], a

	ret

.right
	call vengefly_check_collision_right
	; If we're going to hit a solid tile, don't move
	or a
	ret nz

	; Check x flip of sprite
	ld a, [wShadowOAM + $4C + 3]
	or a
	jr nz, :++

	; Check if we're past half the player before turning around. Necessary since we're updating the position after flipping, the sprite is 16p wide and no security would make vengefly turn around constantly when going straight up or down on player
	ld a, [w_vengefly_position_x_int]
	ld hl, w_player_position_x
	sub [hl]
	jr nc, :+
	cpl
	inc a
	:cp 5
	jr c, :+

	; If not flipped, set to flip
	ld a, %00100000
	ld [wShadowOAM + $40 + 3], a
	ld [wShadowOAM + $44 + 3], a
	ld [wShadowOAM + $48 + 3], a
	ld [wShadowOAM + $4C + 3], a

	:ld a, [w_vengefly_position_x_int]
	inc a
	ld [w_vengefly_position_x_int], a

	ret

.up
	call vengefly_check_collision_up
	; If we're going to hit a solid tile, don't move
	or a
	ret nz

	ld a, [w_vengefly_position_y]
	dec a
	ld [w_vengefly_position_y], a
	ret

.down
	call vengefly_check_collision_down
	; If we're going to hit a solid tile, don't move
	or a
	ret nz

	ld a, [w_vengefly_position_y]
	inc a
	ld [w_vengefly_position_y], a
	ret


draw_vengefly:
	; Update vengefly position
	; Update Y position in OAM
	ld a, [w_vengefly_position_y]
	ld [wShadowOAM + $40], a
	ld [wShadowOAM + $44], a
	add 8
	ld [wShadowOAM + $48], a
	ld [wShadowOAM + $4C], a

	; Check what direction we're going before updating X pos
	ld a, [wShadowOAM + $4C + 3]
	or a
	jr nz, .draw_vengefly_right

.draw_vengefly_left
	; Update X position in OAM
	ld a, [w_vengefly_position_x_int]
	ld [wShadowOAM + $40 + 1], a
	ld [wShadowOAM + $48 + 1], a
	add 8
	ld [wShadowOAM + $44 + 1], a
	ld [wShadowOAM + $4C + 1], a
	ret

.draw_vengefly_right
	; Update X position in OAM
	ld a, [w_vengefly_position_x_int]
	ld [wShadowOAM + $40 + 1], a
	ld [wShadowOAM + $48 + 1], a
	sub 8
	ld [wShadowOAM + $44 + 1], a
	ld [wShadowOAM + $4C + 1], a
	ret