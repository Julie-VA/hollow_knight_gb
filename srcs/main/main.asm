INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "libs/sporbs_lib.asm"
INCLUDE "srcs/main/states/title_screen/title_screen_state.asm"
INCLUDE "srcs/main/utils/utils.asm"
INCLUDE "srcs/main/utils/sprites_utils.asm"
INCLUDE "srcs/main/utils/text_utils.asm"

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

	; Initialise game state at 0
    ld [w_game_state], a

	call wait_vblank

	; Initiliase Sprite Object Library.
	call InitSprObjLibWrapper

	; Turn off LCD
	xor a
	ld [rLCDC], a

	; Load our common text font into VRAM
    call load_text_font_into_vram

	; Turn on LCD
	ld a, LCDCF_ON  | LCDCF_BGON | LCDCF_OBJON | LCDCF_WINON | LCDCF_WIN9C00
	ld [rLCDC], a

	; Initialise display registers
	ld a, %11100100
	ld [rBGP], a
	ld [rOBP0], a

next_game_state::
	call wait_vblank

	call clear_background

	; Turn off LCD
	xor a
	ld [rLCDC], a

	; Set all window values to 0
	ld [rSCX], a
    ld [rSCY], a
    ld [rWX], a
    ld [rWY], a

	call disable_interrupts

	call clear_all_sprites

	; Initiate the next state
    ld a, [w_game_state]
    cp 1 ; 1 = Gameplay
    ; call z, InitGameplayState
    ld a, [w_game_state]
    and a ; 0 = Menu
    call z, init_title_screen_state

	; Update the next state
    ld a, [w_game_state]
    cp 1 ; 1 = Gameplay
    ; jp z, update_gameplay_state
    jp update_title_screen_state


; main:
; 	; We need to make sure we wait for VBlank to be done before moving on to the next frame
; 	call wait_not_vblank

; 	;Then we can wait for VBlank before making any changes
; 	call wait_vblank

; 	; Check the current keys every frame
; 	call update_keys

; check_up:
; 	ld a, [w_cur_keys]
; 	and a, PADF_UP
; 	jp z, check_left
; up:
; 	; Check if knight is already jumping
; 	ld a, [w_knight_jumping]
; 	cp 0
; 	jr nz, .no_jump

; 	; Jump
; 	ld a, JUMP_STRENGHT
; 	ld [w_knight_y_velocity], a

; 	; Mark knight as jumping
; 	ld a, 1
; 	ld [w_knight_jumping], a

; .no_jump
; 	jp main


; ; First, check if the left button is pressed.
; check_left:
; 	ld a, [w_cur_keys]
; 	and a, PADF_LEFT
; 	jp z, check_right
; left:
; 	; Flip knight_top
; 	ld a, %00100000
; 	ld [_OAMRAM + 3], a
; 	; Flip knight_bottom
; 	ld [_OAMRAM + 7], a
; 	; Move the knight_top one pixel to the left. OAMRAM + 1 bc we move X, OAMRAM is Y
; 	ld a, [_OAMRAM + 1]
; 	dec a
; 	ld [_OAMRAM + 1], a
; 	; Move the knight_bottom one pixel to the right.
; 	ld a, [_OAMRAM + 5]
; 	dec a
; 	ld [_OAMRAM + 5], a
; 	call update_knight_walk
; 	jp main

; ; Then check the right button.
; check_right:
; 	ld a, [w_cur_keys]
; 	and a, PADF_RIGHT
; 	jp z, no_input
; right:
; 	; Flip knight_top
; 	xor a
; 	ld [_OAMRAM + 3], a
; 	; Flip knight_bottom
; 	ld [_OAMRAM + 7], a
; 	; Move the Knight1 one pixel to the right. OAMRAM + 1 bc we move X, OAMRAM is Y
; 	ld a, [_OAMRAM + 1]
; 	inc a
; 	ld [_OAMRAM + 1], a
; 	; Move the knight_bottom one pixel to the right.
; 	ld a, [_OAMRAM + 5]
; 	inc a
; 	ld [_OAMRAM + 5], a
; 	call update_knight_walk
; 	jp main

; ; Actions when no input
; no_input:
; 	; Go back to idle
; 	ld a, 1
; 	ld [$FE06], a
; 	jp main

; ; Update walking animation frame
; update_knight_walk:
; 	; Check if current frame is idle, if yes jump right to update_frame
; 	ld a, [$FE06]
; 	cp a, 1
; 	jr z, .update_frame
; 	; Wait 10 frames before updating the walking animation
; 	ld a, [w_frame_counter]
; 	inc a
; 	ld [w_frame_counter], a
; 	cp a, 10 ; Every 10 frames, update the animation frame
; 	jr z, .update_frame
; 	ret ; Else, ret

; .update_frame
; 	ld a, [$FE06]
; 	inc a
; 	cp a, 4
; 	jr nz, .update_sprite_index ; If still in range, set frame 1 or 2 of anim
; 	ld a, 2 ; Else, we're past the last index so set it back to first frame of anim
; .update_sprite_index
; 	ld [$FE06], a

; 	; Reset the frame counter back to 0
; 	xor a
; 	ld [w_frame_counter], a
; 	ret

; update_keys:
; 	; Poll half the controller
; 	ld a, P1F_GET_BTN
; 	call .one_nibble
; 	ld b, a ; B7-4 = 1; B3-0 = unpressed buttons

; 	; Poll the other half
; 	ld a, P1F_GET_DPAD
; 	call .one_nibble
; 	swap a ; A3-0 = unpressed directions; A7-4 = 1
; 	xor a, b ; A = pressed buttons + directions
; 	ld b, a ; B = pressed buttons + directions

; 	; And release the controller
; 	ld a, P1F_GET_NONE
; 	ldh [rP1], a

; 	; Combine with previous w_cur_keys to make w_new_keys
; 	ld a, [w_cur_keys]
; 	xor a, b ; A = keys that changed state
; 	and a, b ; A = keys that changed to pressed
; 	ld [w_new_keys], a
; 	ld a, b
; 	ld [w_cur_keys], a
; 	ret

; .one_nibble
; 	ldh [rP1], a ; switch the key matrix
; 	call .known_ret ; burn 10 cycles calling a known ret
; 	ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
; 	ldh a, [rP1]
; 	ldh a, [rP1] ; this read counts
; 	or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
; .known_ret
; 	ret

; SECTION "Resources", ROM0
; knight_tile_data: INCBIN "resources/knight_sprites.2bpp"
; knight_tile_data_end:

; SECTION "Counter", WRAM0
; w_frame_counter: db

; SECTION "Gameplay Variables", WRAM0
; w_knight_y_velocity: db
; w_knight_jumping: db