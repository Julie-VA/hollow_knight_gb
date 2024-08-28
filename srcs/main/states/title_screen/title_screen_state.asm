INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/text-macros.inc"
INCLUDE "srcs/main/utils/input_utils.asm"

SECTION "TitleScreenState", ROM0

w_press_play_text:: db "press a to play", 255
 
title_screen_tile_data: INCBIN "resources/galacticarmada.2bpp"
title_screen_tile_data_end:
 
title_screen_tile_map: INCBIN "resources/galacticarmada.tilemap"
title_screen_tile_map_end:

init_title_screen_state:
	call draw_title_screen

	; Call our function that draws text onto background/window tiles
    ld de, $99C3
    ld hl, w_press_play_text
    call draw_text_tiles_loop

	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
	ld [rLCDC], a

    ret

draw_title_screen:
	; Copy the tile data
	ld de, title_screen_tile_data
	ld hl, $9340
	ld bc, title_screen_tile_data_end - title_screen_tile_data
	call copy_de_into_memory_at_hl
	
	; Copy the tilemap
	ld de, title_screen_tile_map
	ld hl, $9800
	ld bc, title_screen_tile_map_end - title_screen_tile_map
	jp copy_de_into_memory_at_hl_with_52_offset

update_title_screen_state:
    ; Save the passed value into the variable: m_wait_key
    ; The wait_for_key_function always checks against this vriable
    ld a, PADF_A
    ld [m_wait_key], a

    call wait_for_key_function

    ld a, 1
    ld [w_game_state],a
    jp next_game_state