INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "Crawlid", ROM0

; @param b: X position of left side of sprite
crawlid_ai::
	; Check if we reached max accumulator
	ld a, [w_enemy_1_accu]
	add CRAWLID_ACCU
	cp CRAWLID_ACCU_MAX
	jr c, .crawlid_ai_update_accumulator

	; Reset accumulator
	xor a
	ld [w_enemy_1_accu], a

	; Check if crawlid is moving left or right thanks to orientation of head (0 = left, 1 = right)
	ld a, [wShadowOAM + $38 + 3]
	and %00100000 ; Only the x flip bit is useful for this
	cp %00100000
	jr nz, .crawlid_ai_move_left
	jr .crawlid_ai_move_right

.crawlid_ai_update_accumulator
	ld [w_enemy_1_accu], a
	ret

.crawlid_ai_move_left
	; if reach 104, flip right
	ld a, b
	cp a, 104
	jr z, .crawlid_ai_flip_right

	ld a, [w_enemy_1_position_x]
	dec a
	ld [w_enemy_1_position_x], a

	; Update b so w_enemy_1_position_x can be updated
	ld b, a

	ret

.crawlid_ai_move_right
	; if reach 160, flip left
	ld a, b
	cp a, 160
	jr nc, .crawlid_ai_flip_left

	ld a, [w_enemy_1_position_x]
	inc a
	ld [w_enemy_1_position_x], a
	
	; Update b so w_enemy_position_x can be updated
	ld b, a

	ret

.crawlid_ai_flip_right
	ld a, %00100000
	ld [wShadowOAM + $38 + 3], a
	ld [wShadowOAM + $3C + 3], a

	; Update b so w_enemy_position_x can be updated
	ld a, b
	add 7
	ld b, a

	ret

.crawlid_ai_flip_left
	xor a
	ld [wShadowOAM + $38 + 3], a
	ld [wShadowOAM + $3C + 3], a

	; Update b so w_enemy_position_x can be updated
	ld a, b
	sub 7
	ld b, a

	ret
