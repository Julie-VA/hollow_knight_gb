INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "Crawlid", ROM0

crawlid_ai::
	; Check if crawlid is moving left or right thanks to orientation of head (0 = left, %00100000 = right)
	ld a, [wShadowOAM + $38 + 3]
	and %00100000 ; Only the x flip bit is useful for this
	cp %00100000
	jr nz, .crawlid_ai_move_left
	jr .crawlid_ai_move_right

.crawlid_ai_move_left::
	call crawlid_check_collision_left
	; If we're going to hit a solid tile, turn around
	or a
	jr nz, .crawlid_ai_flip_right

	; Increment decimal
	ld a, [w_enemy_1_position_x_dec]
	add $80 ; Add 0.5
	ld [w_enemy_1_position_x_dec], a

	; Increment integer
	jr nc, .crawlid_ai_done
	ld a, [w_enemy_1_position_x_int]
	dec a
	ld [w_enemy_1_position_x_int], a

	ret

.crawlid_ai_move_right::
	call crawlid_check_collision_right
	; If we're going to hit a solid tile, turn around
	or a
	jr nz, .crawlid_ai_flip_left

	; Increment decimal
	ld a, [w_enemy_1_position_x_dec]
	add $80 ; Add 0.5
	ld [w_enemy_1_position_x_dec], a

	; Increment integer
	jr nc, .crawlid_ai_done
	ld a, [w_enemy_1_position_x_int]
	inc a
	ld [w_enemy_1_position_x_int], a

	ret

.crawlid_ai_flip_right
	ld a, %00100000
	ld [wShadowOAM + $38 + 3], a
	ld [wShadowOAM + $3C + 3], a

	; Update b so w_enemy_1_position_x_int can be updated
	ld a, [w_enemy_1_position_x_int]
	add 7
	ld [w_enemy_1_position_x_int], a

	ret

.crawlid_ai_flip_left
	xor a
	ld [wShadowOAM + $38 + 3], a
	ld [wShadowOAM + $3C + 3], a

	; Update b so w_enemy_1_position_x_int can be updated
	ld a, [w_enemy_1_position_x_int]
	sub 7
	ld [w_enemy_1_position_x_int], a

	ret

.crawlid_ai_done
	ret
