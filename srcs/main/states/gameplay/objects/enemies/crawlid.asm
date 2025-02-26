INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "CrawlidVariables", WRAM0

w_crawlid_active::			db
w_crawlid_position_x_int::	db
w_crawlid_position_x_dec::	db
w_crawlid_position_y::		db
w_crawlid_type::			db
w_crawlid_health::			db


SECTION "Crawlid", ROM0

initialize_crawlid::
	; Set active_byte
	ld a, 1
	ld [w_crawlid_active], a
	; Set y_byte
	ld a, 136
	ld [w_crawlid_position_y], a
	; Set x_byte
	ld a, 32
	ld [w_crawlid_position_x_int], a
	xor a
	ld [w_crawlid_position_x_dec], a
	; Set type_byte
	ld a, CRAWLID
	ld [w_crawlid_type], a
	; Set health_byte
	ld a, CRAWLID_HEALTH
	ld [w_crawlid_health], a

	; Set crawlid_l
	ld a, [w_crawlid_position_y]
	ld b, a
	ld a, [w_crawlid_position_x_int]
	ld c, a
	ld d, $10
	ld e, 0
	call RenderSimpleSprite

	; Set crawlid_r
	ld a, [w_crawlid_position_y]
	ld b, a
	ld a, [w_crawlid_position_x_int]
	add 8
	ld c, a
	ld d, $11
	ld e, 0
	call RenderSimpleSprite

	ret


update_crawlid::
	call crawlid_ai
	call draw_crawlid
	ret



crawlid_ai:
	; Check if crawlid is moving left or right thanks to orientation of head (0 = left, %00100000 = right)
	ld a, [wShadowOAM + $38 + 3]
	and %00100000 ; Only the x flip bit is useful for this
	cp %00100000
	jr nz, .crawlid_ai_move_left
	jr .crawlid_ai_move_right

.crawlid_ai_move_left
	call crawlid_check_collision_left
	; If we're going to hit a solid tile, turn around
	or a
	jr nz, .crawlid_ai_flip_right

	; Increment decimal
	ld a, [w_crawlid_position_x_dec]
	add 128 ; Add 0.5
	ld [w_crawlid_position_x_dec], a

	; Increment integer
	ret nc
	ld a, [w_crawlid_position_x_int]
	dec a
	ld [w_crawlid_position_x_int], a

	ret

.crawlid_ai_move_right
	call crawlid_check_collision_right
	; If we're going to hit a solid tile, turn around
	or a
	jr nz, .crawlid_ai_flip_left

	; Increment decimal
	ld a, [w_crawlid_position_x_dec]
	add $80 ; Add 0.5
	ld [w_crawlid_position_x_dec], a

	; Increment integer
	ret nc
	ld a, [w_crawlid_position_x_int]
	inc a
	ld [w_crawlid_position_x_int], a

	ret

.crawlid_ai_flip_right
	ld a, %00100000
	ld [wShadowOAM + $38 + 3], a
	ld [wShadowOAM + $3C + 3], a

	; Update x position to reflect position of the head
	ld a, [w_crawlid_position_x_int]
	add 7
	ld [w_crawlid_position_x_int], a

	ret

.crawlid_ai_flip_left
	xor a
	ld [wShadowOAM + $38 + 3], a
	ld [wShadowOAM + $3C + 3], a

	; Update x position to reflect position of the head
	ld a, [w_crawlid_position_x_int]
	sub 7
	ld [w_crawlid_position_x_int], a

	ret


draw_crawlid:
	; Update crawlid position
	; Update Y position in OAM
	ld a, [w_crawlid_position_y]
	ld [wShadowOAM + $38], a
	ld [wShadowOAM + $3C], a

	; Check what direction we're going first
	ld a, [wShadowOAM + $38 + 3]
	and %00100000 ; Only the x flip bit is useful for this
	cp %00100000
	jr z, .draw_crawlid_right

.draw_crawlid_left
	; Update X position in OAM
	ld a, [w_crawlid_position_x_int]
	ld [wShadowOAM + $38 + 1], a
	add 8
	ld [wShadowOAM + $3C + 1], a
	ret

.draw_crawlid_right
	; Update X position in OAM
	ld a, [w_crawlid_position_x_int]
	ld [wShadowOAM + $38 + 1], a
	sub 8
	ld [wShadowOAM + $3C + 1], a
	ret
