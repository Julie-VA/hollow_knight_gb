INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "PlayerVariables", WRAM0

w_player_position_x::		db
w_player_position_y::		db

w_player_jumping::			db
w_player_velocity::			db
w_player_jump_strenght::	db
w_player_gravity_accu::		db ; The accumulator is used to travel by GRAVITY every GRAVITY_ACCU_MAX frames
w_player_jump_tracker::		db ; Used to start the falling animation a bit later

SECTION "Player", ROM0

knight_tile_data: INCBIN "resources/sprites.2bpp"
knight_tile_data_end:

initialize_player::
	xor a
	ld [w_frame_counter], a
	ld [w_player_gravity_accu], a
	ld [w_player_jumping], a
	ld [w_player_velocity], a
	ld [w_player_jump_tracker], a

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
	and PADF_UP
	call nz, check_jump

	call cut_jump_check_up_press

    ld a, [w_cur_keys]
    and PADF_LEFT
    call nz, move_left

    ld a, [w_cur_keys]
    and PADF_RIGHT
    call nz, move_right

	ld a, [w_cur_keys]
	and (PADF_LEFT | PADF_RIGHT) ; Mask out left and right buttons
    or 0
	call z, no_direction

	call apply_gravity
	call update_position

	call draw_player ; Should probably move up to update_player

	ret


draw_player:
	; Update Y position in OAM
	ld a, [w_player_position_y]
	ld [_OAMRAM], a
	add a, 8
	ld [_OAMRAM + 4], a

	; Update X position in OAM
	ld a, [w_player_position_x]
	ld [_OAMRAM + 1], a
	ld [_OAMRAM + 5], a

	; Jump check needs to happen before moving check since you can move while jumping but moving anim is only on the ground
	; Check if player is jumping, if so animate jump
	ld a, [w_player_jumping]
	or a
	jr nz, .call_animate_jump

	; Check if player is moving left or right, if so animate walk
	ld a, [w_cur_keys]
	and (PADF_LEFT | PADF_RIGHT)
	or 0
	call nz, animate_walking

	ret

.call_animate_jump
	call animate_jump

	ret
