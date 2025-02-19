INCLUDE "srcs/main/utils/hardware.inc"

SECTION "GameplayState", ROM0

init_gameplay_state::
	call initialize_player
	call initialize_enemies
	call initialize_background

	call init_vblank_interrupt

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_BG9800
	ld [rLCDC], a
	; Set up sprite palette
	ld a, %10010011
	ld [rOBP0], a

	ret


update_gameplay_state::
	; Save what keys were pressed last frame
	ld a, [w_cur_keys]
	ld [w_last_keys], a

	call input

	; Put a call to ResetShadowOAM at the beginning of your main loop
	call ResetShadowOAM

	call update_player
	call update_enemies

	halt

	jp update_gameplay_state
