INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"
INCLUDE "srcs/main/utils/oam_number_table.inc"

SECTION "CrawlidActions", ROM0

crawlid_move_left::
	call crawlid_check_collision_left
	; If we're going to hit a solid tile, turn around
	or a
	jr nz, .flip_right

	call crawlid_check_ledge_left
	; If we're going to walk off a ledge, turn around
	or a
	jr nz, .flip_right

	; Increment decimal
	ld a, [w_crawlid_position_x_dec]
	add 128 ; Add 0.5
	ld [w_crawlid_position_x_dec], a

	; Increment integer
	jr nc, .set_z_flag
	ld a, [w_crawlid_position_x_int]
	dec a
	ld [w_crawlid_position_x_int], a

	jr .set_z_flag

.flip_right
	ld a, %00100000
	ld [wShadowOAM + OAM_CRAWLID_L + 3], a
	ld [wShadowOAM + OAM_CRAWLID_R + 3], a

	; Update x position to reflect position of the head
	ld a, [w_crawlid_position_x_int]
	add 7
	ld [w_crawlid_position_x_int], a

.set_z_flag
	; Set Z flag to 0
	ld a, 1
	or a

	ret


crawlid_move_right::
	call crawlid_check_collision_right
	; If we're going to hit a solid tile, turn around
	or a
	jr nz, .flip_left
	call crawlid_check_ledge_right
	; If we're going to walk off a ledge, turn around
	or a
	jr nz, .flip_left

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

.flip_left
	xor a
	ld [wShadowOAM + OAM_CRAWLID_L + 3], a
	ld [wShadowOAM + OAM_CRAWLID_R + 3], a

	; Update x position to reflect position of the head
	ld a, [w_crawlid_position_x_int]
	sub 7
	ld [w_crawlid_position_x_int], a

	ret

