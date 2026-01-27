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

	; Increase player soul
	call player_gain_soul

	; Initialize w_crawlid_counter_flashing for the flashing logic
	ld a, CRAWLID_FLASHING
	ld [w_crawlid_counter_flashing], a

	; Set sprite palette to OBP1 for flashing (starts flashing right away for instant feedback)
	ld a, [wShadowOAM + OAM_CRAWLID_L + 3]
	or %00010000
	ld [wShadowOAM + OAM_CRAWLID_L + 3], a
	ld a, [wShadowOAM + OAM_CRAWLID_R + 3]
	or %00010000
	ld [wShadowOAM + OAM_CRAWLID_R + 3], a

	; If the next hit kills (ATTACK_DAMAGE >= w_crawlid_health), jp to crawlid_dead
	ld a, [w_crawlid_health]
	cp ATTACK_DAMAGE
	jr z, :+
	jr nc, .take_damage

	; Set w_crawlid_health to 0
	xor a
	ld [w_crawlid_health], a
:
	; Flip crawlid vertically
	ld a, [wShadowOAM + OAM_CRAWLID_L + 3]
	or %01000000
	ld [wShadowOAM + OAM_CRAWLID_L + 3], a
	ld a, [wShadowOAM + OAM_CRAWLID_R + 3]
	or %01000000
	ld [wShadowOAM + OAM_CRAWLID_R + 3], a

	jp crawlid_dead

.take_damage
	; Take damage
	ld a, [w_crawlid_health]
	sub ATTACK_DAMAGE
	ld [w_crawlid_health], a

	ret


crawlid_recoil::
	; The crawlid will be launched 2 pixels to the side for CRAWLID_RECOIL frames
	ld a, [w_crawlid_counter_flashing]
	cp a, CRAWLID_FLASHING - CRAWLID_RECOIL
	jp c, update_crawlid.update_crawlid_player_collision

	ld a, [w_crawlid_hit_side]
	or a
	jr z, .launch_left

.launch_right
	call crawlid_launch_right
	jp update_crawlid.update_crawlid_player_collision

.launch_left
	call crawlid_launch_left
	jp update_crawlid.update_crawlid_player_collision


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


crawlid_dead::
	ld a, [w_crawlid_counter_flashing]
	dec a
	ld [w_crawlid_counter_flashing], a

	; When crawlid stops flashing, make it inactive
	or a
	jr z, .make_inactive
	cp 19 ; In the last 19 frames of the flashing, do a fade out animation
	jr c, .fade_out
	jr z, .fade_out


	; Check bit 2 to flash every 4 frames. OBP0 when bit 2 == 0 and OBP1 when bit 2 == 1
	bit 2, a
	jr nz, .flashing_obp1

.flashing_obp0
	ld a, [wShadowOAM + OAM_CRAWLID_L + 3]
	res 4, a
	ld [wShadowOAM + OAM_CRAWLID_L + 3], a
	ld a, [wShadowOAM + OAM_CRAWLID_R + 3]
	res 4, a
	ld [wShadowOAM + OAM_CRAWLID_R + 3], a
	ret

.flashing_obp1
	ld a, [wShadowOAM + OAM_CRAWLID_L + 3]
	set 4, a
	ld [wShadowOAM + OAM_CRAWLID_L + 3], a
	ld a, [wShadowOAM + OAM_CRAWLID_R + 3]
	set 4, a
	ld [wShadowOAM + OAM_CRAWLID_R + 3], a
	ret

; Fade out by going all white, light gray then dark gray in this order, each color stays up for 6 frames, hide sprite off-screen at the end
.fade_out
	cp 19
	jr nz, :+
	ld a, %00000011
	ld [rOBP1], a
	ret
:
	cp 13
	jr nz, :+
	ld a, %01010111
	ld [rOBP1], a
	ret
:
	cp 7
	jr nz, :+
	ld a, %10101011
	ld [rOBP1], a
	ret
:
	cp 1
	ret nz
	; Hide crawlid
	xor a
	ld [wShadowOAM + OAM_CRAWLID_L], a
	ld [wShadowOAM + OAM_CRAWLID_R], a
	ld [wShadowOAM + OAM_CRAWLID_L + 1], a
	ld [wShadowOAM + OAM_CRAWLID_R + 1], a
	ret

.make_inactive
	xor a
	ld [w_crawlid_active], a

	; Reset OBP1
	ld a, %00100111
	ld [rOBP1], a

	ret