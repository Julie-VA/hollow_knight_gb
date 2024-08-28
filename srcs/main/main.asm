INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/utils.asm"

SECTION "GameVariables", WRAM0

w_last_keys:: db
w_cur_keys:: db
w_new_keys:: db
w_game_state:: db

SECTION "Header", ROM0[$100]

	jp entry_point

	ds $150 - @, 0 ; Make room for the header

entry_point:
	; Do not turn the LCD off outside of VBlank

initialise:
	call wait_vblank

	call turn_off_lcd

	; Copy the Knight tile in VRAM
	ld de, knight_tile_data
	ld hl, $8000
	ld bc, knight_tile_data_end - knight_tile_data
	call mem_copy

	call clear_oam

	; Set knight_top
	ld hl, _OAMRAM
	ld a, 128 + 16
	ld [hli], a
	ld a, 16 + 8
	ld [hli], a
	xor a
	ld [hli], a
	ld [hl], a

	; Set knight_bottom
	ld hl, _OAMRAM + 4
	ld a, 136 + 16
	ld [hli], a
	ld a, 16 + 8
	ld [hli], a
	ld a, 1
	ld [hli], a
	xor a
	ld [hl], a

	ld a, LCDCF_ON | LCDCF_OBJON
	call turn_on_lcd

	; During the first (blank) frame, initialize display registers
	; ld a, %11100100
	; ld [rBGP], a ; Background register
	ld a, %11100100
	ld [rOBP0], a ; Object register 0

	; Initialize global variables
	xor a
	ld [w_frame_counter], a
	ld [w_cur_keys], a
	ld [w_new_keys], a
	ld [w_knight_y_velocity], a
	ld [w_knight_jumping], a

main:
	; We need to make sure we wait for VBlank to be done before moving on to the next frame
	call wait_not_vblank

	;Then we can wait for VBlank before making any changes
	call wait_vblank

	; Check the current keys every frame
	call update_keys

check_up:
	ld a, [w_cur_keys]
	and a, PADF_UP
	jp z, check_left
up:
	; Check if knight is already jumping
	ld a, [w_knight_jumping]
	cp 0
	jr nz, .no_jump

	; Jump
	ld a, JUMP_STRENGHT
	ld [w_knight_y_velocity], a

	; Mark knight as jumping
	ld a, 1
	ld [w_knight_jumping], a

.no_jump
	jp main


; First, check if the left button is pressed.
check_left:
	ld a, [w_cur_keys]
	and a, PADF_LEFT
	jp z, check_right
left:
	; Flip knight_top
	ld a, %00100000
	ld [_OAMRAM + 3], a
	; Flip knight_bottom
	ld [_OAMRAM + 7], a
	; Move the knight_top one pixel to the left. OAMRAM + 1 bc we move X, OAMRAM is Y
	ld a, [_OAMRAM + 1]
	dec a
	ld [_OAMRAM + 1], a
	; Move the knight_bottom one pixel to the right.
	ld a, [_OAMRAM + 5]
	dec a
	ld [_OAMRAM + 5], a
	call update_knight_walk
	jp main

; Then check the right button.
check_right:
	ld a, [w_cur_keys]
	and a, PADF_RIGHT
	jp z, no_input
right:
	; Flip knight_top
	xor a
	ld [_OAMRAM + 3], a
	; Flip knight_bottom
	ld [_OAMRAM + 7], a
	; Move the Knight1 one pixel to the right. OAMRAM + 1 bc we move X, OAMRAM is Y
	ld a, [_OAMRAM + 1]
	inc a
	ld [_OAMRAM + 1], a
	; Move the knight_bottom one pixel to the right.
	ld a, [_OAMRAM + 5]
	inc a
	ld [_OAMRAM + 5], a
	call update_knight_walk
	jp main

; Actions when no input
no_input:
	; Go back to idle
	ld a, 1
	ld [$FE06], a
	jp main

; Update walking animation frame
update_knight_walk:
	; Check if current frame is idle, if yes jump right to update_frame
	ld a, [$FE06]
	cp a, 1
	jr z, .update_frame
	; Wait 10 frames before updating the walking animation
	ld a, [w_frame_counter]
	inc a
	ld [w_frame_counter], a
	cp a, 10 ; Every 10 frames, update the animation frame
	jr z, .update_frame
	ret ; Else, ret

.update_frame
	ld a, [$FE06]
	inc a
	cp a, 4
	jr nz, .update_sprite_index ; If still in range, set frame 1 or 2 of anim
	ld a, 2 ; Else, we're past the last index so set it back to first frame of anim
.update_sprite_index
	ld [$FE06], a

	; Reset the frame counter back to 0
	xor a
	ld [w_frame_counter], a
	ret

update_keys:
	; Poll half the controller
	ld a, P1F_GET_BTN
	call .one_nibble
	ld b, a ; B7-4 = 1; B3-0 = unpressed buttons

	; Poll the other half
	ld a, P1F_GET_DPAD
	call .one_nibble
	swap a ; A3-0 = unpressed directions; A7-4 = 1
	xor a, b ; A = pressed buttons + directions
	ld b, a ; B = pressed buttons + directions

	; And release the controller
	ld a, P1F_GET_NONE
	ldh [rP1], a

	; Combine with previous w_cur_keys to make w_new_keys
	ld a, [w_cur_keys]
	xor a, b ; A = keys that changed state
	and a, b ; A = keys that changed to pressed
	ld [w_new_keys], a
	ld a, b
	ld [w_cur_keys], a
	ret

.one_nibble
	ldh [rP1], a ; switch the key matrix
	call .known_ret ; burn 10 cycles calling a known ret
	ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
	ldh a, [rP1]
	ldh a, [rP1] ; this read counts
	or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
.known_ret
	ret

SECTION "Resources", ROM0
knight_tile_data: INCBIN "resources/knight_sprites.2bpp"
knight_tile_data_end:

SECTION "Counter", WRAM0
w_frame_counter: db

SECTION "Gameplay Variables", WRAM0
w_knight_y_velocity: db
w_knight_jumping: db