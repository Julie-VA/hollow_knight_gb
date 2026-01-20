INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

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
	ld [w_player_jump_strenght], a

	ld a, [w_player_position_x]
	add 16
	ld [w_player_position_x], a

	ret