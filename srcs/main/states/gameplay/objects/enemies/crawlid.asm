INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"
INCLUDE "srcs/main/utils/tile_number_table.inc"
INCLUDE "srcs/main/utils/oam_number_table.inc"

SECTION "CrawlidVariables", WRAM0

w_crawlid_active::			db
w_crawlid_position_x_int::	db
w_crawlid_position_x_dec::	db
w_crawlid_position_y::		db
w_crawlid_type::			db
w_crawlid_health::			db

w_crawlid_counter_flashing::	db
w_crawlid_hit_side::			db ; To know on which side the crawlid got hit and launch it accordingly. 0 = hit on the right, 1 = hit on the left


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

	xor a
	ld [w_crawlid_counter_flashing], a
	ld [w_crawlid_hit_side], a

	; Set crawlid_l
	ld a, [w_crawlid_position_y]
	ld b, a
	ld a, [w_crawlid_position_x_int]
	ld c, a
	ld d, T_CRAWLID_L
	ld e, 0
	call RenderSimpleSprite

	; Set crawlid_r
	ld a, [w_crawlid_position_y]
	ld b, a
	ld a, [w_crawlid_position_x_int]
	add 8
	ld c, a
	ld d, T_CRAWLID_R
	ld e, 0
	call RenderSimpleSprite

	ret


update_crawlid::
	; If the crawlid just got hit and is in the recoil window, it can't act and are launched
	ld a, [w_crawlid_counter_flashing]
	cp a, CRAWLID_FLASHING - CRAWLID_RECOIL
	jr nc, crawlid_recoil

	; Skip if crawlid is in recoil
	call crawlid_ai

.update_crawlid_player_collisions
	call crawlid_check_player_collision

	; Check if player is attacking, if they are, check if crawlid is getting hit
	ld a, [w_player_counter_attack]
	or a
	jr z, :+
	cp ATTACK_TIME + 1 ; We want to check against the active window of attack, not the after effects
	jr nc, :+
	call crawlid_check_slash_collision
:

.update_crawlid_draw
	call draw_crawlid
	ret


crawlid_ai:
	; Check if crawlid is in the air and apply gravity
	call crawlid_check_collision_down
	or a
	jr nz, .crawlid_ai_move
	ld a, [w_crawlid_position_y]
	inc a
	ld [w_crawlid_position_y], a
	ret

.crawlid_ai_move
	; Check if crawlid is moving left or right thanks to orientation of head (0 = left, %00100000 = right)
	ld a, [wShadowOAM + OAM_CRAWLID_L + 3]
	and %00100000 ; Only the x flip bit is useful for this
	cp %00100000
	call nz, crawlid_move_left ; Set zero flag to 0 at the end to avoid calling move_right after
	call z, crawlid_move_right
	ret


crawlid_hit::
	; If crawlid is still flashing, it's still invincible so we can ignore this part
	ld a, [w_crawlid_counter_flashing]
	or a
	ret nz

	; Take damage
	ld a, [w_crawlid_health]
	sub ATTACK_DAMAGE

	; Initialize w_crawlid_counter_flashing for the flashing logic
	ld a, CRAWLID_FLASHING
	ld [w_crawlid_counter_flashing], a

	; Set sprite palette to OBP1 for flashing (starts flashing right away for instant feedback)
	ld a, [wShadowOAM + OAM_CRAWLID_L + 3]
	set 4, a
	ld [wShadowOAM + OAM_CRAWLID_L + 3], a
	ld a, [wShadowOAM + OAM_CRAWLID_R + 3]
	set 4, a
	ld [wShadowOAM + OAM_CRAWLID_R + 3], a
	ret


crawlid_recoil:
	; The crawlid will be launched 2 pixels to the side for the 1st 4 frames of recoil (12f), the last 8f not moving
	ld a, [w_crawlid_counter_flashing]
	cp a, CRAWLID_FLASHING - CRAWLID_RECOIL - 4
	jp c, update_crawlid.update_crawlid_player_collisions

	ld a, [w_crawlid_hit_side]
	or a
	jr z, .launch_left

.launch_right
	call crawlid_launch_right
	jp update_crawlid.update_crawlid_player_collisions

.launch_left
	call crawlid_launch_left
	jp update_crawlid.update_crawlid_player_collisions


crawlid_dead:
	xor a
	ld [wShadowOAM + OAM_CRAWLID_L], a
	ld [wShadowOAM + OAM_CRAWLID_R], a
	ld [wShadowOAM + OAM_CRAWLID_L + 1], a
	ld [wShadowOAM + OAM_CRAWLID_R + 1], a
	ret


draw_crawlid:
	; Check if crawlid got hit and is flashing
	ld a, [w_crawlid_counter_flashing]
	or a
	jr z, .normal_case

.flashing_case
	dec a
	ld [w_crawlid_counter_flashing], a

	; Check bit 2 to flash every 4 frames. Hidden when bit 2 == 0 and shown when bit 2 == 1
	bit 2, a
	jr nz, .flashing_obp1

.flashing_obp0
	ld a, [wShadowOAM + OAM_CRAWLID_L + 3]
	res 4, a
	ld [wShadowOAM + OAM_CRAWLID_L + 3], a
	ld a, [wShadowOAM + OAM_CRAWLID_R + 3]
	res 4, a
	ld [wShadowOAM + OAM_CRAWLID_R + 3], a
	jr .normal_case

.flashing_obp1
	ld a, [wShadowOAM + OAM_CRAWLID_L + 3]
	set 4, a
	ld [wShadowOAM + OAM_CRAWLID_L + 3], a
	ld a, [wShadowOAM + OAM_CRAWLID_R + 3]
	set 4, a
	ld [wShadowOAM + OAM_CRAWLID_R + 3], a

.normal_case
	; Update crawlid position
	; Update Y position in OAM
	ld a, [w_crawlid_position_y]
	ld [wShadowOAM + OAM_CRAWLID_L], a
	ld [wShadowOAM + OAM_CRAWLID_R], a

	; Check what direction we're going first
	ld a, [wShadowOAM + OAM_CRAWLID_L + 3]
	and %00100000 ; Only the x flip bit is useful for this
	cp %00100000
	jr z, .draw_crawlid_right

.draw_crawlid_left
	; Update X position in OAM
	ld a, [w_crawlid_position_x_int]
	ld [wShadowOAM + OAM_CRAWLID_L + 1], a
	add 8
	ld [wShadowOAM + OAM_CRAWLID_R + 1], a
	ret

.draw_crawlid_right
	; Update X position in OAM
	ld a, [w_crawlid_position_x_int]
	ld [wShadowOAM + OAM_CRAWLID_L + 1], a
	sub 8
	ld [wShadowOAM + OAM_CRAWLID_R + 1], a
	ret


