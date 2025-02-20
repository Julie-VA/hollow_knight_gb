INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "VengeflyVariables", WRAM0

w_vengefly_active::			db
w_vengefly_position_x_int::	db
w_vengefly_position_x_dec::	db
w_vengefly_position_y::		db
w_vengefly_type::			db
w_vengefly_health::			db


SECTION "Vengefly", ROM0

initialize_vengefly::
	; Set active_byte
	ld a, 1
	ld [w_vengefly_active], a
	; Set y_byte
	ld a, 32
	ld [w_vengefly_position_y], a
	; Set x_byte
	ld a, 48
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
	; Check if player is within 48 pixels radius
	ld a, [w_player_position_x]
	ld hl, w_vengefly_position_x_int
	sub [hl]
	jr nc, .vengefly_ai_absolute_x ; If no carry, difference is already positive
	cpl ; Else, invert bits and add 1 to get absolute value
	inc a
.vengefly_ai_absolute_x
	cp 48
	jr nc, .vengefly_ai_outside_radius

	ld a, [w_player_position_y]
	ld hl, w_vengefly_position_y
	sub [hl]
	jr nc, .vengefly_ai_absolute_y
	cpl
	inc a
.vengefly_ai_absolute_y
	cp 48
	jr nc, .vengefly_ai_outside_radius

	; If we reach here, that means the player is within the radius.
	ld a, [w_vengefly_position_x_int]
	dec a
	ld [w_vengefly_position_x_int], a
	ret


.vengefly_ai_outside_radius
	; If the player is outside the radius, the vengefly will randomly move a little in one of the 4 directions
	; Generate pseudo random number
	ld a, [rDIV]
	and %00000011 ; Only keep last 2 bits since we want 4 options
	cp 0
	jr z, .vengefly_ai_outside_radius_move_left
	cp 1
	jr z, .vengefly_ai_outside_radius_move_right
	cp 2
	jr z, .vengefly_ai_outside_radius_move_up
	cp 3
	jr z, .vengefly_ai_outside_radius_move_down

.vengefly_ai_outside_radius_move_left
	ld a, [w_vengefly_position_x_int]
	dec a
	ld [w_vengefly_position_x_int], a
	ret

.vengefly_ai_outside_radius_move_right
	ld a, [w_vengefly_position_x_int]
	inc a
	ld [w_vengefly_position_x_int], a
	ret

.vengefly_ai_outside_radius_move_up
	ld a, [w_vengefly_position_y]
	dec a
	ld [w_vengefly_position_y], a
	ret

.vengefly_ai_outside_radius_move_down
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

	; Update X position in OAM
	ld a, [w_vengefly_position_x_int]
	ld [wShadowOAM + $40 + 1], a
	ld [wShadowOAM + $48 + 1], a
	add 8
	ld [wShadowOAM + $44 + 1], a
	ld [wShadowOAM + $4C + 1], a
	ret