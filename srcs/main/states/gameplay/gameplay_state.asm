INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/text-macros.inc"

SECTION "GameplayState", ROM0

init_gameplay_state::
	call initialize_player
	call initialize_background

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_BG9800
	ld [rLCDC], a

	ret


update_gameplay_state::
	; Save what keys were pressed last frame
	ld a, [w_cur_keys]
	ld [w_last_keys], a

	call input

	; Put a call to ResetShadowOAM at the beginning of your main loop
	call ResetShadowOAM

	call update_player

	call wait_not_vblank
	call wait_vblank

	ld a, HIGH(wShadowOAM)
	call hOAMDMA

	jp update_gameplay_state
