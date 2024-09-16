INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/text-macros.inc"

SECTION "GameplayState", ROM0

init_gameplay_state::
    call initialize_player

    ; Turn the LCD on
    ld a, LCDCF_ON  | LCDCF_BGON | LCDCF_OBJON | LCDCF_BG9800
    ld [rLCDC], a

    ret

update_gameplay_state::

    ; Save the keys last frame
    ld a, [w_cur_keys]
    ld [w_last_keys], a

    call input

    ; Then put a call to ResetShadowOAM at the beginning of your main loop.
    ; call ResetShadowOAM
    ; call reset_oam_sprite_address

	call update_player

	; Clear remaining sprites to avoid lingering rogue sprites
	; call clear_remaining_sprites

	call wait_not_vblank
	call wait_vblank

	jp update_gameplay_state
