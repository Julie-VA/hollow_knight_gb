INCLUDE "srcs/main/utils/hardware.inc"

SECTION "TitleScreenState", ROM0

title_screen_tile_data: INCBIN "resources/title_screen.2bpp"
title_screen_tile_data_end:

title_screen_tile_map: INCBIN "resources/title_screen.tilemap"
title_screen_tile_map_end:


init_title_screen_state::
	call draw_title_screen

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
	ld [rLCDC], a

	; Invert palette
	ld a, %00011011
	ld [rBGP], a

	; Enable sound globally
	ld a, $80
	ld [rAUDENA], a
	; Enable all channels in stereo
	ld a, $FF
	ld [rAUDTERM], a
	; Set volume
	ld a, $77
	ld [rAUDVOL], a

	; Init song
	ld hl, OST_title
	call hUGE_init

	call init_vblank_interrupt

    ret


draw_title_screen::
	; Copy the tile data
	ld de, title_screen_tile_data
	ld hl, $8800
	ld bc, title_screen_tile_data_end - title_screen_tile_data
	call copy_de_into_memory_at_hl
	
	; Copy the tilemap
	ld de, title_screen_tile_map
	ld hl, $9800
	ld bc, title_screen_tile_map_end - title_screen_tile_map
	jp copy_de_into_memory_at_hl


update_title_screen_state::
    ; Save the passed value into the variable: m_wait_key
    ; wait_for_key_title always checks against this variable
    ld a, PADF_START
    ld [m_wait_key], a

	call wait_for_key_title

	; Reset
	call clear_title_screen_tiles
	ld a, %11100100
	ld [rBGP], a

    ld a, 1
    ld [w_game_state],a
    jp next_game_state