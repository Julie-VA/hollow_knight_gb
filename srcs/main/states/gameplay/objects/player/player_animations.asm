INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"
INCLUDE "srcs/main/utils/tile_number_table.inc"
INCLUDE "srcs/main/utils/oam_number_table.inc"

SECTION "PlayerAnimations", ROM0

animate_attack::
	ld a, [w_player_attacking]
	cp ATTACK_UP
	jr nc, .animate_attack_y_update_pos ; If w_player_attacking = 3 or 4 (up or down), display the vertical slash

; This diplays and updates the position of the horizontal slash (left, right)
.animate_attack_x_update_pos
	; Update Y position of attack animation
	ld a, [w_player_position_y]
	ld [wShadowOAM + OAM_SLASH_1_X], a ; top left
	ld [wShadowOAM + OAM_SLASH_2_X], a ; top right
	add a, 8
	ld [wShadowOAM + OAM_SLASH_3_X], a ; bottom left
	ld [wShadowOAM + OAM_SLASH_4_X], a ; bottom right

	; Check if we're attacking left or right to position it left or right of the player
	ld a, [w_player_attacking]
	cp ATTACK_LEFT
	jr nz, .animate_attack_x_update_pos_right

.animate_attack_x_update_pos_left
	; Update X position of attack animation
	ld a, [w_player_position_x]
	sub a, 8
	ld [wShadowOAM + OAM_SLASH_1_X + 1], a ; top left
	ld [wShadowOAM + OAM_SLASH_3_X + 1], a ; bottom left
	sub a, 8
	ld [wShadowOAM + OAM_SLASH_2_X + 1], a ; top right
	ld [wShadowOAM + OAM_SLASH_4_X + 1], a ; bottom right
	jp draw_attack.done

.animate_attack_x_update_pos_right
	; Update X position of attack animation
	ld a, [w_player_position_x]
	add a, 8
	ld [wShadowOAM + OAM_SLASH_1_X + 1], a ; top left
	ld [wShadowOAM + OAM_SLASH_3_X + 1], a ; bottom left
	add a, 8
	ld [wShadowOAM + OAM_SLASH_2_X + 1], a ; top right
	ld [wShadowOAM + OAM_SLASH_4_X + 1], a ; bottom right
	jp draw_attack.done

; This diplays and updates the position of the vertical slash (up, down)
.animate_attack_y_update_pos
	; Check if the attack is x flipped to place the sprites correctly
	ld a, [wShadowOAM + OAM_SLASH_1_Y + 3]
	and %00100000 ; Only the x flip bit is useful for this
	cp %00100000
	jr z, .animate_attack_y_update_pos_flipped

.animate_attack_y_update_pos_not_flipped
	; Update X position of attack animation
	ld a, [w_player_position_x]
	sub a, 4
	ld [wShadowOAM + OAM_SLASH_1_Y + 1], a ; top left
	ld [wShadowOAM + OAM_SLASH_3_Y + 1], a ; bottom left
	add a, 8
	ld [wShadowOAM + OAM_SLASH_2_Y + 1], a ; top right
	ld [wShadowOAM + OAM_SLASH_4_Y + 1], a ; bottom right
	jr .animate_attack_y_update_pos_check

.animate_attack_y_update_pos_flipped
	; Update X position of attack animation
	ld a, [w_player_position_x]
	sub a, 4
	ld [wShadowOAM + OAM_SLASH_2_Y + 1], a ; top right
	ld [wShadowOAM + OAM_SLASH_4_Y + 1], a ; bottom right
	add a, 8
	ld [wShadowOAM + OAM_SLASH_1_Y + 1], a ; top left
	ld [wShadowOAM + OAM_SLASH_3_Y + 1], a ; bottom left

.animate_attack_y_update_pos_check
	; Check if we're attacking up or down to position it above or below the player
	ld a, [w_player_attacking]
	cp ATTACK_UP
	jr nz, .animate_attack_y_update_pos_down

.animate_attack_y_update_pos_up
	; Update Y position of attack animation
	ld a, [w_player_position_y]
	sub a, 8
	ld [wShadowOAM + OAM_SLASH_3_Y], a ; bottom left
	ld [wShadowOAM + OAM_SLASH_4_Y], a ; bottom right
	sub a, 8
	ld [wShadowOAM + OAM_SLASH_1_Y], a ; top left
	ld [wShadowOAM + OAM_SLASH_2_Y], a ; top right
	jp draw_attack.done

.animate_attack_y_update_pos_down
	; Update Y position of attack animation
	ld a, [w_player_position_y]
	add a, 16
	ld [wShadowOAM + OAM_SLASH_3_Y], a ; bottom left
	ld [wShadowOAM + OAM_SLASH_4_Y], a ; bottom right
	add a, 8
	ld [wShadowOAM + OAM_SLASH_1_Y], a ; top left
	ld [wShadowOAM + OAM_SLASH_2_Y], a ; top right
	jp draw_attack.done


animate_after_effect::
	; Check if it's the 1st frame of after effect
	cp ATTACK_TIME
	jr nz, .animate_after_effect_update_pos

	; Check whether to mask out vertical or horizontal slash sprites
	ld a, [w_player_attacking]
	cp ATTACK_UP
	jr nc, .animate_after_effect_mask_y

.animate_after_effect_mask_x
	; Mask out the horizontal attack sprites
	xor a
	ld [wShadowOAM + OAM_SLASH_1_X], a ; top left
	ld [wShadowOAM + OAM_SLASH_2_X], a ; top right
	ld [wShadowOAM + OAM_SLASH_3_X], a ; bottom left
	ld [wShadowOAM + OAM_SLASH_4_X], a ; bottom right
	ld [wShadowOAM + OAM_SLASH_1_X + 1], a ; top left
	ld [wShadowOAM + OAM_SLASH_2_X + 1], a ; bottom left
	ld [wShadowOAM + OAM_SLASH_3_X + 1], a ; top right
	ld [wShadowOAM + OAM_SLASH_4_X + 1], a ; bottom right
	jr .animate_after_effect_update_pos

.animate_after_effect_mask_y
	; Mask out the vertical attack sprites
	xor a
	ld [wShadowOAM + OAM_SLASH_1_Y], a ; top left
	ld [wShadowOAM + OAM_SLASH_2_Y], a ; top right
	ld [wShadowOAM + OAM_SLASH_3_Y], a ; bottom left
	ld [wShadowOAM + OAM_SLASH_4_Y], a ; bottom right
	ld [wShadowOAM + OAM_SLASH_1_Y + 1], a ; top left
	ld [wShadowOAM + OAM_SLASH_2_Y + 1], a ; bottom left
	ld [wShadowOAM + OAM_SLASH_3_Y + 1], a ; top right
	ld [wShadowOAM + OAM_SLASH_4_Y + 1], a ; bottom right

.animate_after_effect_update_pos
	ld a, [w_player_attacking]
	cp ATTACK_UP
	jr nc, .animate_after_effect_y_update_pos ; If w_player_attacking = 3 or 4 (up or down), display the vertical after effect

; This diplays and updates the position of the horizontal after effect (left, right)
.animate_after_effect_x_update_pos
	; Update Y position of after effect animation
	ld a, [w_player_position_y]
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_1_X], a ; left
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_2_X], a ; right

	; Check if we're attacking left or right to position it left or right of the player
	ld a, [w_player_attacking]
	cp ATTACK_LEFT
	jr nz, .animate_after_effect_x_update_pos_right

.animate_after_effect_x_update_pos_left
	; Update X position of attack animation
	ld a, [w_player_position_x]
	sub a, 8
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_1_X + 1], a ; left
	sub a, 8
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_2_X + 1], a ; right
	jp draw_attack.done

.animate_after_effect_x_update_pos_right
	; Update X position of attack animation
	ld a, [w_player_position_x]
	add a, 8
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_1_X + 1], a ; left
	add a, 8
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_2_X + 1], a ; right
	jp draw_attack.done

; This diplays and updates the position of the vertical after effect (up, down)
.animate_after_effect_y_update_pos
	; Check if the after effect is x flipped to place the sprites correctly
	ld a, [wShadowOAM + OAM_SLASH_AFTER_EFFECT_1_Y + 3]
	and %00100000 ; Only the x flip bit is useful for this
	cp %00100000
	jr z, .animate_after_effect_y_update_pos_flipped

.animate_after_effect_y_update_pos_not_flipped
	; Update Y position of after effect animation
	ld a, [w_player_position_x]
	sub a, 4
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_1_Y + 1], a ; bottom
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_2_Y + 1], a ; top
	jr .animate_after_effect_y_update_pos_check

.animate_after_effect_y_update_pos_flipped
	; Update Y position of after effect animation
	ld a, [w_player_position_x]
	add a, 4
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_1_Y + 1], a ; bottom
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_2_Y + 1], a ; top

.animate_after_effect_y_update_pos_check
	; Check if we're attacking up or down to position it above or below the player
	ld a, [w_player_attacking]
	cp ATTACK_UP
	jr nz, .animate_after_effect_y_update_pos_down

.animate_after_effect_y_update_pos_up
	; Update Y position of after effect animation
	ld a, [w_player_position_y]
	sub a, 8
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_2_Y], a ; top
	sub a, 8
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_1_Y], a ; bottom
	jp draw_attack.done

.animate_after_effect_y_update_pos_down
	; Update Y position of after effect animation
	ld a, [w_player_position_y]
	add a, 16
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_2_Y], a ; top
	add a, 8
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_1_Y], a ; bottom
	jp draw_attack.done


animate_attack_end::
	; Check whether to mask out vertical or horizontal slash sprites
	ld a, [w_player_attacking]
	cp ATTACK_UP
	jr nc, .animate_attack_end_mask_y

.animate_attack_end_mask_x
	; Mask out horizontal after effect sprites
	xor a
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_1_X], a ; left
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_2_X], a ; right
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_1_X + 1], a ; left
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_2_X + 1], a ; right

.animate_attack_end_mask_y
	; Mask out vertical after effect sprites
	xor a
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_1_Y], a ; left
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_2_Y], a ; right
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_1_Y + 1], a ; left
	ld [wShadowOAM + OAM_SLASH_AFTER_EFFECT_2_Y + 1], a ; right

	jp draw_attack.done


animate_jump::
	; Check if player is going up
	ld a, [w_player_counter_jump]
	cp 2
	jr nc, .animate_jump_falling

.animate_jump_rising
	; Check if left or right were pressed in the last or current frame, to make sure we use the correct animation frame
	ld a, [w_last_keys]
	and (PADF_LEFT | PADF_RIGHT)
	ld b, a
	ld a, [w_cur_keys]
	and (PADF_LEFT | PADF_RIGHT)
	or a, b
	jr nz, .animate_jump_falling ; The falling animation has the cape up which we also want when rising and moving

.animate_jump_rising_idle
	ld a, T_PLAYER_BOT_IDLE
	ld [wShadowOAM + OAM_PLAYER_BOT + 2], a
	jp draw_player.done

.animate_jump_falling
	ld a, T_PLAYER_BOT_WALK_2 ; Falling and walk 2 animations are the same
	ld [wShadowOAM + OAM_PLAYER_BOT + 2], a
	jp draw_player.done


animate_walk::
	; Check if current frame is idle, if yes jump right to animate_walk_update_frame
	ld a, [wShadowOAM + OAM_PLAYER_BOT + 2] ; = wShadowOAM + $06 = 2nd OAMRAM spot's tile number
	cp T_PLAYER_BOT_IDLE
	jr z, .animate_walk_update_frame
	; Wait 10 frames before updating the walk animation
	ld a, [w_player_counter_walk]
	inc a
	ld [w_player_counter_walk], a
	cp 10 ; Every 10 frames, update the animation frame
	jr z, .animate_walk_update_frame
	jp draw_player.done ; Else, ret

.animate_walk_update_frame
	ld a, [wShadowOAM + OAM_PLAYER_BOT + 2]
	cp T_PLAYER_BOT_WALK_2 ; If we're past the animations including the sword, sub 3. The following flag checks do a <= T_PLAYER_BOT_WALK_2
	jr z, :+ ; If z is set, a == T_PLAYER_BOT_WALK_2
	jr c, :+ ; If c is set, a < T_PLAYER_BOT_WALK_2
	sub 3
:
	inc a ; Used for cycling between the walking animation sprites
	cp T_PLAYER_BOT_WALK_2 + 1 ; 2 animation frames, so 3 is out of range
	jr nz, .animate_walk_update_sprite_index ; If still in range, set frame 1 or 2 of anim
	ld a, T_PLAYER_BOT_WALK_1 ; Else, we're past the last index so set it back to first frame of anim

.animate_walk_update_sprite_index
	ld [wShadowOAM + OAM_PLAYER_BOT + 2], a

	; Reset the frame counter back to 0
	xor a
	ld [w_player_counter_walk], a
	jp draw_player.done