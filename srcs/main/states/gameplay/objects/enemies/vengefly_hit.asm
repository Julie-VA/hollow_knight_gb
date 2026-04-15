INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"
INCLUDE "srcs/main/utils/oam_number_table.inc"

SECTION "VengeflyHitVariables", WRAM0

w_vengefly_counter_flashing::	db
w_vengefly_hit_side::			db ; To know on which side the vengefly got hit and launch it accordingly. 0 = hit on the right, 1 = hit on the left


SECTION "VengeflyHit", ROM0

vengefly_hit::
	; If vengefly is still flashing, it's still invincible so we can ignore this part
	ld a, [w_vengefly_counter_flashing]
	or a
	ret nz

	; Increase player soul
	call player_gain_soul

	; Initialize w_vengefly_counter_flashing for the flashing logic
	ld a, VENGEFLY_FLASHING
	ld [w_vengefly_counter_flashing], a

	; Set sprite palette to OBP1 for flashing (starts flashing right away for instant feedback)
	ld a, [wShadowOAM + OAM_VENGEFLY_TL + 3]
	or %00010000
	ld [wShadowOAM + OAM_VENGEFLY_TL + 3], a
	ld a, [wShadowOAM + OAM_VENGEFLY_TR + 3]
	or %00010000
	ld [wShadowOAM + OAM_VENGEFLY_TR + 3], a

	; If the next hit kills (ATTACK_DAMAGE >= w_vengefly_health), jp to vengefly_dead
	ld a, [w_vengefly_health]
	cp ATTACK_DAMAGE
	jr z, :+
	jr nc, .take_damage

	; Set w_vengefly_health to 0
	xor a
	ld [w_vengefly_health], a
:
	; Flip vengefly vertically
	ld a, [wShadowOAM + OAM_VENGEFLY_TL + 3]
	or %01000000
	ld [wShadowOAM + OAM_VENGEFLY_TL + 3], a
	ld a, [wShadowOAM + OAM_VENGEFLY_TR + 3]
	or %01000000
	ld [wShadowOAM + OAM_VENGEFLY_TR + 3], a

	; jp vengefly_dead
    ret

.take_damage
	; Take damage
	ld a, [w_vengefly_health]
	sub ATTACK_DAMAGE
	ld [w_vengefly_health], a

	ret