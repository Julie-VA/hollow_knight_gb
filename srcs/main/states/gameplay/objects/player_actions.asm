INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "PlayerMovement", ROM0

attack::
	; Ret if player is already attacking
	ld a, [w_player_attacking]
	or a
	ret nz

; Check if down is pressed, if it is, check if player is jumping, if they aren't set w_player_attacking to 3 (up), if they are set w_player_attacking to 4 (down)
.attack_check_down
	ld a, [w_cur_keys]
	and PADF_DOWN
	jr z, .attack_check_left
	ld a, [w_player_jumping]
	or a
	jr nz, .attack_check_down_jumping
	ld a, 3
	ld [w_player_attacking], a
	; Set no y flip
	ld b, 0
	jr .attack_set_attributes_y_slash
	
.attack_check_down_jumping
	ld a, 4
	ld [w_player_attacking], a
	; Set y flip
	ld b, %01000000
	jr .attack_set_attributes_y_slash

; Check if left is pressed, if it is set w_player_attacking to 2 (left)
.attack_check_left
	ld a, [w_cur_keys]
	and PADF_LEFT
	jr z, .attack_check_right
	ld a, 2
	ld [w_player_attacking], a
	; Set x flip
	ld a, %00100000
	jr .attack_set_attributes_x_slash

; Check if right is pressed, if it is set w_player_attacking to 1 (right)
.attack_check_right
	ld a, [w_cur_keys]
	and PADF_RIGHT
	jr z, .attack_check_up
	ld a, 1
	ld [w_player_attacking], a
	; Set no x flip
	xor a
	jr .attack_set_attributes_x_slash

; Check if up is pressed, if it is set w_player_attacking to 3 (up)
.attack_check_up
	ld a, [w_cur_keys]
	and PADF_UP
	jr z, .attack_no_dir
	ld a, 3
	ld [w_player_attacking], a
	; Set no y flip
	ld b, 0
	jr .attack_set_attributes_y_slash

; If no direction is pressed while attacking, set w_player_attacking to the direction the player is facing
.attack_no_dir
	; Check attributes of player head, to see if it's flipped
	ld a, [wShadowOAM + $00 + 3]
	or a
	jr z, .attack_no_dir_flip_right
.attack_no_dir_flip_left
	; Set w_player_attacking to 2 (left)
	ld a, 2
	ld [w_player_attacking], a
	; Set x flip
	ld a, %00100000
	jr .attack_set_attributes_x_slash
.attack_no_dir_flip_right
	; Set w_player_attacking to 1 (right)
	ld a, 1
	ld [w_player_attacking], a
	; Set no x flip
	xor a
	jr .attack_set_attributes_x_slash

; This is used to x flip the horizontal slashes (used in .attack_check_left, .attack_check_right and .attack_no_dir)
.attack_set_attributes_x_slash
	; Set attack and after effect attributes
	; attack
	ld [wShadowOAM + $08 + 3], a
	ld [wShadowOAM + $0C + 3], a
	ld [wShadowOAM + $10 + 3], a
	ld [wShadowOAM + $14 + 3], a
	; after effect
	ld [wShadowOAM + $18 + 3], a
	ld [wShadowOAM + $1C + 3], a
	ret

; This is used to x flip in the direction of the player and potentially y flip (with b) the vertical slashes (used in .attack_check_down and .attack_check_up)
.attack_set_attributes_y_slash
	; Check attributes of player head, to see if it's flipped
	ld a, [wShadowOAM + $00 + 3]
	or a
	jr z, .attack_set_attributes_y_slash_flip_right
.attack_set_attributes_y_slash_flip_left
	; Set x flip
	ld a, %00100000
	jr .attack_set_attributes_y_slash_finish
.attack_set_attributes_y_slash_flip_right
	; Set no x flip
	xor a
.attack_set_attributes_y_slash_finish
	; b contains the information on whether or not we need to y flip
	or a, b

	; Set attack and after effect attributes
	; attack
	ld [wShadowOAM + $20 + 3], a
	ld [wShadowOAM + $24 + 3], a
	ld [wShadowOAM + $28 + 3], a
	ld [wShadowOAM + $2C + 3], a
	; after effect
	ld [wShadowOAM + $30 + 3], a
	ld [wShadowOAM + $34 + 3], a
	ret


move_left::
	; Flip knight_top
	ld a, %00100000
	ld [wShadowOAM + $00 + 3], a
	; Flip knight_bottom
	ld [wShadowOAM + $04 + 3], a

	call check_collision_left
	; If we're going to hit a solid tile, don't move
	cp 1
	ret z

	; Decrease the player's x position
	ld a, [w_player_position_x]
	sub PLAYER_MOVE_SPEED
	ld [w_player_position_x], a

	ret


move_right::
	; Flip knight_top
	xor a
	ld [wShadowOAM + $00 + 3], a
	; Flip knight_bottom
	ld [wShadowOAM + $04 + 3], a

	call check_collision_right
	; If we're going to hit a solid tile, don't move
	cp 1
	ret z

	; Increase the player's x position
	ld a, [w_player_position_x]
	add PLAYER_MOVE_SPEED
	ld [w_player_position_x], a

	ret


no_direction::
	; Go back to idle
	ld a, 1
	ld [wShadowOAM + $04 + 2], a
	ret


cut_jump_check_up_press::
	ld a, [w_last_keys] ; Load the previous frame's key state
	and PADF_UP
	ret z ; If up wasn't pressed in the last frame, ret

	ld a, [w_cur_keys] ; Load the current frame's key state
	and PADF_UP
	ret nz ; If up is still pressed, ret

.cut_jump:
	; Check if player is already jumping
	ld a, [w_player_jumping]
	or 0
	ret z

	; Player is jumping, stop upwards momentum
	xor a
	ld [w_player_jump_strenght], a

	ret


start_jump::
	; Check if player is already jumping or airborne
	ld a, [w_player_jumping]
	or 0
	ret nz
	ld a, [w_player_airborne]
	or 0
	ret nz

	; Jump
	ld a, JUMP_STRENGHT
	ld [w_player_jump_strenght], a

	; Mark player as jumping and airborne
	ld a, 1
	ld [w_player_jumping], a
	ld [w_player_airborne], a

	ret


jump::
	; Check if player is jumping (needed?)
	ld a, [w_player_jumping]
	or 0
	ret z

	; Is the player still going up?
	ld a, [w_player_jump_strenght]
	or a
	jr z, .jump_stop ; If w_player_jump_strenght = 0, player is falling

	; Decrease jump strenght
	ld a, [w_player_jump_strenght]
	add MAX_UP_VELOCITY
	ld [w_player_jump_strenght], a

	; Update position
	ld a, [w_player_position_y]
	add MAX_UP_VELOCITY
	ld [w_player_position_y], a

	ret

.jump_stop
	xor a
	ld [w_player_jumping], a
	ret


apply_gravity::
	; Check if player is jumping, if they are ret
	ld a, [w_player_jumping]
	or 0
	ret nz

	; Check if player is on the ground, if they aren't apply gravity
	call check_collision_ground
	or 0
	jr z, .apply_gravity_body

	; Check if player was airborne, if they were reset all relevant variables
	ld a, [w_player_airborne]
	or 0
	ret z

	xor a
	ld [w_player_velocity], a
	ld [w_player_gravity_accu], a
	ld [w_player_jump_tracker], a
	ld [w_player_airborne], a
	ret

.apply_gravity_body
	; Mark player as airborne
	ld a, 1
	ld [w_player_airborne], a

	; Check if reached max accumulator
	ld a, [w_player_gravity_accu]
	add GRAVITY_ACCU
	cp GRAVITY_ACCU_MAX
	jr c, .apply_gravity_update_accumulator

	; Reset accumulator
	xor a
	ld [w_player_gravity_accu], a

	; Keep track of where we are in the jump for animation
	ld a, [w_player_jump_tracker]
	inc a
	ld [w_player_jump_tracker], a
	; inc w_player_jump_tracker works?

	; Check that max velocity hasn't been reached yet
	ld a, [w_player_velocity]
	cp MAX_DOWN_VELOCITY
	jr z, .apply_gravity_update_position

	; Apply gravity
	add GRAVITY
	ld [w_player_velocity], a
	jr .apply_gravity_update_position

.apply_gravity_update_accumulator
	ld [w_player_gravity_accu], a

.apply_gravity_update_position
	; Update Y position based on Y velocity
	ld a, [w_player_position_y]
	ld hl, w_player_velocity
	add a, [hl]
	ld [w_player_position_y], a

	ret