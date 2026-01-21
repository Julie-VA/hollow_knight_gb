INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "PlayerHitVariables", WRAM0

w_player_hit_side::	db ; To know on which side the player got hit and launch him accordingly. 0 = hit on the left, 1 = hit on the right


SECTION "PlayerHit", ROM0

handle_player_hit::
	; If player is still flashing, they're still invincible so we can ignore this part
	ld a, [w_player_counter_flashing]
	or a
	ret nz

	; Take 1 mask of damage
	ld a, [w_player_masks]
	dec a
	ld [w_player_masks], a

	; Initialize w_player_counter_flashing for the flashing logic in player.asm/draw_player
	ld a, INVINCIBILITY_TIME
	ld [w_player_counter_flashing], a

	; Stop jumping
	xor a
	ld [w_player_jumping], a
	ld [w_player_jump_strength], a

	; Give upwards momentum
	ld a, STRENGTH_LAUNCH_UP
	ld [w_player_jump_strength], a
	ld a, 1
	ld [w_player_jumping], a


	ret