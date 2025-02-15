INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "Vengefly", ROM0

vengefly_ai::
	ld a, [w_enemy_2_position_x]
	inc a
	ld [w_enemy_2_position_x], a
	ret