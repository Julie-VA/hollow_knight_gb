INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"
INCLUDE "srcs/main/utils/oam_number_table.inc"

SECTION "CrawlidHitVariables", WRAM0

w_crawlid_counter_flashing::	db
w_crawlid_hit_side::			db ; To know on which side the crawlid got hit and launch it accordingly. 0 = hit on the right, 1 = hit on the left

SECTION "CrawlidHit", ROM0

crawlid_hit::
	; If crawlid is still flashing, it's still invincible so we can ignore this part
	ld a, [w_crawlid_counter_flashing]
	or a
	ret nz

	ld a, [w_crawlid_health]
	cp ATTACK_DAMAGE
	jr nc, .apply_hit
	xor a
	ld [w_crawlid_health], a
	jp crawlid_dead

.apply_hit
	; Increase player soul
	call player_gain_soul

	; Take damage
	ld a, [w_crawlid_health]
	sub ATTACK_DAMAGE
	ld [w_crawlid_health], a

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


crawlid_recoil::
	; The crawlid will be launched 2 pixels to the side for CRAWLID_RECOIL frames
	ld a, [w_crawlid_counter_flashing]
	cp a, CRAWLID_FLASHING - CRAWLID_RECOIL
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


; Check if crawlid is facing left or right, then perform check wall accordingly (front or rear of sprite), then launch if it's not going to hit a wall
crawlid_launch_left::
	ld a, [wShadowOAM + OAM_CRAWLID_L + 3]
	and %00100000 ; and x flip bit
	cp %00100000
	jr z, .check_rear

.check_front
	call crawlid_check_collision_left
	or a
	ret nz

	jr .launch

.check_rear
	call crawlid_check_collision_rear_left
	or a
	ret nz

.launch
	; Move 2 pixels
	ld a, [w_crawlid_position_x_int]
	sub 2
	ld [w_crawlid_position_x_int], a

	ret

; Check if crawlid is facing left or right, then perform check wall accordingly (front or rear of sprite), then launch if it's not going to hit a wall
crawlid_launch_right::
	ld a, [wShadowOAM + OAM_CRAWLID_L + 3]
	and %00100000 ; and x flip bit
	cp %00100000
	jr z, .check_front

.check_rear
	; Return if front or back of sprite is going to hit a solid tile
	call crawlid_check_collision_rear_right
	or a
	ret nz

	jr .launch

.check_front
	call crawlid_check_collision_right
	or a
	ret nz

.launch
	; Move 2 pixels
	ld a, [w_crawlid_position_x_int]
	add 2
	ld [w_crawlid_position_x_int], a

	ret


crawlid_dead:
	xor a
	ld [wShadowOAM + OAM_CRAWLID_L], a
	ld [wShadowOAM + OAM_CRAWLID_R], a
	ld [wShadowOAM + OAM_CRAWLID_L + 1], a
	ld [wShadowOAM + OAM_CRAWLID_R + 1], a
	ret