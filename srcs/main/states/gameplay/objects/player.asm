INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "PlayerVariables", WRAM0

w_player_position_x::	db
w_player_position_y::	db
w_player_velocity_y::	db
w_player_jumping::		db
w_player_up_speed::		db
w_gravity_accumulator::	db

SECTION "Player", ROM0

knight_tile_data: INCBIN "resources/knight_sprites.2bpp"
knight_tile_data_end:

initialize_player::
	xor a
	ld [w_frame_counter], a
	ld [w_gravity_accumulator], a
	ld [w_player_jumping], a
	ld [w_player_velocity_y], a

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

	call check_up_press
	cp a, 0 ; If a = 0: up was not pressed, if it was, a = 1
	call nz, cut_jump

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

	call apply_gravity
	call update_position
	ld a, [w_player_position_y]
	ld [_OAMRAM], a
	add a, 8
	ld [_OAMRAM + 4], a

	ret

check_up_press:
	ld a, [w_last_keys] ; Load the previous frame's key state
    and PADF_UP
    jr z, .no_up ; If up wasn't pressed in the last frame, skip

    ld a, [w_cur_keys] ; Load the current frame's key state
    and PADF_UP
    jr nz, .no_up ; If up is still pressed, skip

	; "return" 1 if up was pressed, 0 if it wasn't
    ld a, 1
	ret
.no_up:
	ld a, 0
    ret

move_up:
	call check_jump
	call apply_gravity
	call update_position
	; Move knight top and knight bottom up
	ld a, [w_player_position_y]
	ld [_OAMRAM], a
	add a, 8
	ld [_OAMRAM + 4], a
	ret

cut_jump:
	; Check if player is already jumping
	ld a, [w_player_jumping]
	cp 0
	jr z, .done

	; Player is jumping, cancel upwards momentum
	xor a
	ld [w_player_up_speed], a
.done
	ret

check_jump:
	; Check if player is already jumping
	ld a, [w_player_jumping]
	cp 0
	jr nz, .no_jump

	; Jump
	ld a, JUMP_STRENGHT
	ld [w_player_up_speed], a

	; Mark player as jumping
	ld a, 1
	ld [w_player_jumping], a
.no_jump
	ret

apply_gravity:
	ld a, [w_player_jumping]
    cp 0
    jr z, .done

	; Is the player going up?
	ld a, [w_player_up_speed]
	cp 0
	jr z, .falling

	; Decrease jump strenght until 0
	ld a, [w_player_up_speed]
	add MAX_UP_VELOCITY
	ld [w_player_up_speed], a

	; Make player go up
	ld a, MAX_UP_VELOCITY
	ld [w_player_velocity_y], a

	jr .done

.falling
	; Check if reached max accumulator
	ld a, [w_gravity_accumulator]
	add GRAVITY_ACCU
	cp GRAVITY_ACCU_MAX
	jr c, .update_accumulator

	; Reset accumulator
	xor a
	ld [w_gravity_accumulator], a

	; Check that max velocity hasn't been reached yet
	ld a, [w_player_velocity_y]
	cp MAX_DOWN_VELOCITY
	jr z, .done
	; Apply gravity
	add GRAVITY
	ld [w_player_velocity_y], a
	ld [w_player_velocity_y], a

.update_accumulator:
    ld [w_gravity_accumulator], a

.done:
    ret

update_position:
	; Update Y position based on Y velocity
    ld a, [w_player_position_y]
	ld hl, w_player_velocity_y
    add a, [hl]
    ld [w_player_position_y], a

	; Check if player is on the ground
    cp 144 ; Assuming 144 is the ground level
    jp c, .not_on_ground

	ld a, 144
	ld [w_player_position_y], a

	xor a
    ld [w_player_velocity_y], a
	ld [w_gravity_accumulator], a
	ld [w_player_jumping], a
.not_on_ground:
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
	; Move knight top and knight bottom 1 pixel to the left
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