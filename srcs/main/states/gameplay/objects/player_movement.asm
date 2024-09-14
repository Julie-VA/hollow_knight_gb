INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "PlayerMovement", ROM0

move_up::
	call check_jump
	call apply_gravity
	call update_position

	ret


move_left::
	; Flip knight_top
	ld a, %00100000
	ld [_OAMRAM + 3], a
	; Flip knight_bottom
	ld [_OAMRAM + 7], a

	; Decrease the player's x position
	ld a, [w_player_position_x]
	sub PLAYER_MOVE_SPEED
	ld [w_player_position_x], a

	call animate_walking

	ret


move_right::
	; Flip knight_top
	xor a
	ld [_OAMRAM + 3], a
	; Flip knight_bottom
	ld [_OAMRAM + 7], a

	; Increase the player's x position
	ld a, [w_player_position_x]
	add PLAYER_MOVE_SPEED
	ld [w_player_position_x], a

	call animate_walking

	ret


no_direction::
	; Go back to idle
	ld a, 1
	ld [$FE06], a
	ret


cut_jump_check_up_press::
	ld a, [w_last_keys] ; Load the previous frame's key state
	and PADF_UP
	jr z, .no_up ; If up wasn't pressed in the last frame, skip

	ld a, [w_cur_keys] ; Load the current frame's key state
	and PADF_UP
	jr nz, .no_up ; If up is still pressed, skip

	call cut_jump

.no_up:
	ret


cut_jump::
	; Check if player is already jumping
	ld a, [w_player_jumping]
	or 0
	jr z, .done

	; Player is jumping, cancel upwards momentum
	xor a
	ld [w_player_jump_strenght], a

.done
	ret


check_jump::
	; Check if player is already jumping
	ld a, [w_player_jumping]
	or 0
	jr nz, .no_jump

	; Jump
	ld a, JUMP_STRENGHT
	ld [w_player_jump_strenght], a

	; Mark player as jumping
	ld a, 1
	ld [w_player_jumping], a

.no_jump
	ret


apply_gravity::
	ld a, [w_player_jumping]
	or 0
	jr z, .done

	; Is the player going up?
	ld a, [w_player_jump_strenght]
	or a
	jr z, .falling ; If w_player_jump_strenght < 1, player is falling

	; Decrease jump strenght
	ld a, [w_player_jump_strenght]
	add MAX_UP_VELOCITY
	ld [w_player_jump_strenght], a

	; Make player go up
	ld a, MAX_UP_VELOCITY
	ld [w_player_velocity], a

	jr .done

.falling
	; Check if reached max accumulator
	ld a, [w_player_gravity_accu]
	add GRAVITY_ACCU
	cp GRAVITY_ACCU_MAX
	jr c, .update_accumulator

	; Reset accumulator
	xor a
	ld [w_player_gravity_accu], a

	; Keep track of where we are in the jump for animation
	ld a, [w_player_jump_tracker]
	inc a
	ld [w_player_jump_tracker], a

	; Check that max velocity hasn't been reached yet
	ld a, [w_player_velocity]
	cp MAX_DOWN_VELOCITY
	jr z, .done
	; Apply gravity
	add GRAVITY
	ld [w_player_velocity], a


.update_accumulator:
	ld [w_player_gravity_accu], a

.done:
	ret


update_position::
	; Update Y position based on Y velocity
	ld a, [w_player_position_y]
	ld hl, w_player_velocity
	add a, [hl]
	ld [w_player_position_y], a

	; Check if player is on the ground
	cp 144 ; Assuming 144 is the ground level
	jp c, .not_on_ground

	ld a, 144
	ld [w_player_position_y], a

	xor a
	ld [w_player_velocity], a
	ld [w_player_gravity_accu], a
	ld [w_player_jumping], a
	ld [w_player_jump_tracker], a

.not_on_ground:
	ret
