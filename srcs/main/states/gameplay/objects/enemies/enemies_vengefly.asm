INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "Vengefly", ROM0

vengefly_ai::
	; Restore current enemy address
	ld h, d
	ld l, e

	ld bc, enemy_x_byte
	add hl, bc
	ld a, [hl]
	inc a
	ld [hl], a

	; Restore current enemy address
	ld h, d
	ld l, e

	jp enemies_ai.enemies_ai_loop_end