INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"
INCLUDE "srcs/main/utils/oam_number_table.inc"

SECTION "PlayerMovement", ROM0

attack::
	; Ret if player is already attacking
	ld a, [w_player_attacking]
	or a
	ret nz

	; Ret if player is holding A to attack (must press it)
	ld a, [w_last_keys]
	and PADF_A
	ret nz

; Check if down is pressed, if it is, check if player is jumping, if they aren't set w_player_attacking to 3 (up), if they are set w_player_attacking to 4 (down)
.attack_check_down
	ld a, [w_cur_keys]
	and PADF_DOWN
	jr z, .attack_check_left
	ld a, [w_player_airborne]
	or a
	jr nz, .attack_check_down_jumping
	ld a, ATTACK_UP
	ld [w_player_attacking], a
	; Set no y flip
	ld b, 0
	jr .attack_set_attributes_y_slash
	
.attack_check_down_jumping
	ld a, ATTACK_DOWN
	ld [w_player_attacking], a
	; Set y flip
	ld b, %01000000
	jr .attack_set_attributes_y_slash

; Check if left is pressed, if it is set w_player_attacking to 2 (left)
.attack_check_left
	ld a, [w_cur_keys]
	and PADF_LEFT
	jr z, .attack_check_right
	ld a, ATTACK_LEFT
	ld [w_player_attacking], a
	; Set x flip
	ld a, %00100000
	jr .attack_set_attributes_x_slash

; Check if right is pressed, if it is set w_player_attacking to 1 (right)
.attack_check_right
	ld a, [w_cur_keys]
	and PADF_RIGHT
	jr z, .attack_check_up
	ld a, ATTACK_RIGHT
	ld [w_player_attacking], a
	; Set no x flip
	xor a
	jr .attack_set_attributes_x_slash

; Check if up is pressed, if it is set w_player_attacking to 3 (up)
.attack_check_up
	ld a, [w_cur_keys]
	and PADF_UP
	jr z, .attack_no_dir
	ld a, ATTACK_UP
	ld [w_player_attacking], a
	; Set no y flip
	ld b, 0
	jr .attack_set_attributes_y_slash

; If no direction is pressed while attacking, set w_player_attacking to the direction the player is facing
.attack_no_dir
	; Check attributes of player head, to see if it's flipped
	ld a, [wShadowOAM + OAM_PLAYER_TOP + 3]
	or a
	jr z, .attack_no_dir_flip_right
.attack_no_dir_flip_left
	; Set w_player_attacking to 2 (left)
	ld a, ATTACK_LEFT
	ld [w_player_attacking], a
	; Set x flip
	ld a, %00100000
	jr .attack_set_attributes_x_slash
.attack_no_dir_flip_right
	; Set w_player_attacking to 1 (right)
	ld a, ATTACK_RIGHT
	ld [w_player_attacking], a
	; Set no x flip
	xor a
	jr .attack_set_attributes_x_slash

; This is used to x flip the horizontal slashes (used in .attack_check_left, .attack_check_right and .attack_no_dir)
.attack_set_attributes_x_slash
	; Set attack and after effect attributes
	; attack
	ld [wShadowOAM + OAM_SLASH_1_X + 3], a
	ld [wShadowOAM + OAM_SLASH_2_X + 3], a
	ld [wShadowOAM + OAM_SLASH_3_X + 3], a
	ld [wShadowOAM + OAM_SLASH_4_X + 3], a
	; after effect
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_1_X + 3], a
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_2_X + 3], a
	ret

; This is used to x flip in the direction of the player and potentially y flip (with b) the vertical slashes (used in .attack_check_down and .attack_check_up)
.attack_set_attributes_y_slash
	; Check attributes of player head, to see if it's flipped
	ld a, [wShadowOAM + OAM_PLAYER_TOP + 3]
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
	ld [wShadowOAM + OAM_SLASH_1_Y + 3], a
	ld [wShadowOAM + OAM_SLASH_2_Y + 3], a
	ld [wShadowOAM + OAM_SLASH_3_Y + 3], a
	ld [wShadowOAM + OAM_SLASH_4_Y + 3], a
	; after effect
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_1_Y + 3], a
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_2_Y + 3], a
	ret


move_left::
	; Flip knight_top
	ld a, %00100000
	ld [wShadowOAM + OAM_PLAYER_TOP + 3], a
	; Flip knight_bottom
	ld [wShadowOAM + OAM_PLAYER_BOT + 3], a

	call check_wall_collision_left
	; If we're going to hit a solid tile, don't move
	dec a
	ret z

	; Decrease the player's x position
	ld a, [w_player_position_x]
	sub PLAYER_MOVE_SPEED
	ld [w_player_position_x], a

	ret


move_right::
	; Flip knight_top
	xor a
	ld [wShadowOAM + OAM_PLAYER_TOP + 3], a
	; Flip knight_bottom
	ld [wShadowOAM + OAM_PLAYER_BOT + 3], a

	call check_wall_collision_right
	; If we're going to hit a solid tile, don't move
	dec a
	ret z

	; Increase the player's x position
	ld a, [w_player_position_x]
	add PLAYER_MOVE_SPEED
	ld [w_player_position_x], a

	ret


no_direction::
	; Go back to idle
	ld a, 1
	ld [wShadowOAM + OAM_PLAYER_BOT + 2], a
	ret


cut_jump::
	ld a, [w_last_keys] ; Load the previous frame's key state
	and PADF_UP
	ret z ; If up wasn't pressed in the last frame, ret

	ld a, [w_cur_keys] ; Load the current frame's key state
	and PADF_UP
	ret nz ; If up is still pressed, ret

	; Stop the jump
	xor a
	ld [w_player_jumping], a
	ld [w_player_jump_strenght], a
	; Set some UP_VELOCITY so player floats a bit before coming back down (like in jump.jump_stop)
	ld a, MAX_UP_VELOCITY
	ld [w_player_velocity], a

	ret


start_jump::
	; Check if player is already jumping or airborne
	ld a, [w_player_jumping]
	ld hl, w_player_airborne
	or a, [hl]
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
	call check_wall_collision_up
	or a
	jr z, .jump_body

	xor a
	ld [w_player_jump_strenght], a
	ld [w_player_velocity], a ; This is important, we set it after a normal jump to make it floaty but having velocity after the player hit their head would make them clip through
	ld [w_player_jumping], a
	ret

.jump_body
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

	; We don't use w_player_velocity for the rising part of the jump since we're only ever going up by MAX_UP_VELOCITY, however we need to set the velocity in preparation
	; for the fall down, as still having some velocity upwards helps give that floaty feeling at the apex of the jump
	ld a, MAX_UP_VELOCITY
	ld [w_player_velocity], a
	ret


apply_gravity::
	; Check if player is on the ground, if they aren't apply gravity
	call check_wall_collision_down
	or a
	jr z, .apply_gravity_check_up

	; Check if player was airborne, if they were reset all relevant variables
	ld a, [w_player_airborne]
	or a
	ret z

	xor a
	ld [w_player_gravity_accu], a
	ld [w_player_counter_jump], a
	ld [w_player_airborne], a
	ld [w_player_velocity], a
	ret

.apply_gravity_check_up
	; Necessary because if the jump ends right before an obstacle, we don't want to have velocity upwards, making us potentially clip through stuff
	call check_wall_collision_up
	or a
	jr z, .apply_gravity_body

	ld a, [w_player_counter_jump]
	or a
	jr nz, .apply_gravity_body
	xor a
	ld [w_player_velocity], a

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
	ld a, [w_player_counter_jump]
	inc a
	ld [w_player_counter_jump], a

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

	; Check if player is on the ground, if they are, check if player position y is odd or even, if it's odd we're inside the floor (we move 2 pixels at a time at MAX_DOWN_VELOCITY)
	call check_wall_collision_down
	or a
	ret z

	ld a, [w_player_position_y]
	bit 0, a
	ret z ; Ret if position is even

	ld a, [w_player_position_y] ; Correct if position is odd
	dec a
	ld [w_player_position_y], a
	ret
