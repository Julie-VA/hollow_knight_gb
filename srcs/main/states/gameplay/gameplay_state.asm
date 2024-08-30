INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/text-macros.inc"

SECTION "GameplayVariables", WRAM0

w_score:: ds 6
w_lives:: db

SECTION "GameplayState", ROM0

w_score_text::  db "score", 255
w_lives_text::  db "lives", 255

init_gameplay_state::
	; Load our common text font into VRAM
    call load_text_font_into_vram

    ld a, 3
    ld [w_lives], a

	; Reset each byte of score
    xor a
    ld [w_score], a
    ld [w_score+1], a
    ld [w_score+2], a
    ld [w_score+3], a
    ld [w_score+4], a
    ld [w_score+5], a

    call initialize_player

    ; Initiate STAT interrupts
    ; call initialize_stat_interrupts

    ; Call Our function that draws text onto background/window tiles
    ld de, $9c00
    ld hl, w_score_text
    call draw_text_tiles_loop

    ; Call Our function that draws text onto background/window tiles
    ld de, $9c0d
    ld hl, w_lives_text
    call draw_text_tiles_loop

    ; call draw_score
    ; call draw_lives

	; Reset the window’s position back to 7,0
    ld a, 0
    ld [rWY], a
    ld a, 7
    ld [rWX], a

    ; Turn the LCD on
    ld a, LCDCF_ON  | LCDCF_BGON | LCDCF_OBJON | LCDCF_WINON | LCDCF_WIN9C00 | LCDCF_BG9800
    ld [rLCDC], a

    ret

update_gameplay_state::

    ; Save the keys last frame
    ld a, [w_cur_keys]
    ld [w_last_keys], a

    call input

    ; Then put a call to ResetShadowOAM at the beginning of your main loop.
    call ResetShadowOAM
    call reset_oam_sprite_address

	; call update_player

	; Clear remaining sprites to avoid lingering rogue sprites
	call clear_remaining_sprites

	jp update_gameplay_state
