INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "PlayerVariables", WRAM0

w_player_position_x:: db
w_player_position_y:: db

SECTION "Player", ROM0

knight_tile_data: INCBIN "resources/knight_sprites.2bpp"
knight_tile_data_end:

initialize_player::
	xor a
	ld [w_frame_counter], a

	ld a, 16
    ld [w_player_position_x], a
	ld a, 144
    ld [w_player_position_y], a

    ; Copy the player's tile data into VRAM
    ld de, knight_tile_data
    ld hl, PLAYER_TILES_START
    ld bc, knight_tile_data_end - knight_tile_data
    call copy_de_into_memory_at_hl

	; Set knight_top
	ld hl, _OAMRAM
	ld a, [w_player_position_y]
	ld [hli], a
	ld a, [w_player_position_x]
	ld [hli], a
	xor a
	ld [hli], a
	ld [hl], a

	; Set knight_bottom
	ld hl, _OAMRAM + 4
	ld a, [w_player_position_y]
	add a, 8
	ld [hli], a
	ld a, [w_player_position_x]
	ld [hli], a
	ld a, 1
	ld [hli], a
	xor a
	ld [hl], a

	ret

update_player::

update_player_handle_input:
    ld a, [w_cur_keys]
    and PADF_LEFT
    call nz, move_left

    ld a, [w_cur_keys]
    and PADF_RIGHT
    call nz, move_right

	ld a, [w_cur_keys]
	and (PADF_LEFT | PADF_RIGHT) ; Mask out left and right buttons
    cp 0
	call z, no_input

	ret

move_left:
	; Flip knight_top
	ld a, %00100000
	ld [_OAMRAM + 3], a
	; Flip knight_bottom
	ld [_OAMRAM + 7], a

    ; Decrease the player's x position
    ld a, [w_player_position_x]
    sub PLAYER_MOVE_SPEED
	; dec a
    ld [w_player_position_x], a

	call update_player_horizontally
    ret

move_right:
	; Flip knight_top
	xor a
	ld [_OAMRAM + 3], a
	; Flip knight_bottom
	ld [_OAMRAM + 7], a

    ; Increase the player's x position
    ld a, [w_player_position_x]
    add PLAYER_MOVE_SPEED
	; inc a
    ld [w_player_position_x], a

	call update_player_horizontally
    ret

no_input: 
	; Go back to idle
	ld a, 1
	ld [$FE06], a
	ret

update_player_horizontally:
	; Move knight top and knight bottow 1 pixel to the left
	ld [_OAMRAM + 1], a
	ld [_OAMRAM + 5], a

	; Check if current frame is idle, if yes jump right to update_frame
	ld a, [$FE06] ; $FE06 = 2nd OAMRAM spot
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