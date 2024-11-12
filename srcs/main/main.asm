INCLUDE "srcs/main/utils/hardware.inc"

SECTION "GameVariables", WRAM0

w_last_keys:: db
w_cur_keys:: db
w_new_keys:: db
w_game_state:: db


SECTION "Header", ROM0[$100]

	jp entry_point

	ds $150 - @, 0 ; Make room for the header

entry_point:
	; Turn off audio
	xor a
    ld [rNR52], a

	; Initialize game state at 0
    ld [w_game_state], a

	call wait_vblank

	; Initialize Sprite Object Library.
	call InitSprObjLibWrapper

	; Turn off LCD
	xor a
	ld [rLCDC], a

	; Turn on LCD
	ld a, LCDCF_ON  | LCDCF_BGON | LCDCF_OBJON
	ld [rLCDC], a

	; Initialize display registers
	ld a, %11100100
	ld [rBGP], a
	ld [rOBP0], a


next_game_state::
	call wait_vblank

	call clear_background_tilemap

	; Turn off LCD
	xor a
	ld [rLCDC], a

	call clear_oam

	call disable_interrupts

	; Initiate the next state
    ld a, [w_game_state]
    cp 1 ; 1 = Gameplay
    call z, init_gameplay_state
    ld a, [w_game_state]
    or a ; 0 = Menu
    call z, init_title_screen_state

	; Update the next state
    ld a, [w_game_state]
    cp 1 ; 1 = Gameplay
    jp z, update_gameplay_state
    jp update_title_screen_state
