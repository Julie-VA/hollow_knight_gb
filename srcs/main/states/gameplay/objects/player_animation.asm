INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "PlayerAnimations", ROM0

animate_attack::
	; Check if it's the 1st frame of attack
	or a
	jr nz, .animate_attack_update_pos

	; Check attributes of player head, to see if it's flipped
	ld a, [$FE03]
	or a
	jr z, .animate_attack_flip_right

.animate_attack_flip_left
	; Flip attack and after effect to the left
	ld a, %00100000
	; attack
	ld [$FE08 + 3], a
	ld [$FE0C + 3], a
	ld [$FE10 + 3], a
	ld [$FE14 + 3], a
	; after effect
	ld [$FE18 + 3], a
	ld [$FE1C + 3], a
	jr .animate_attack_update_pos

.animate_attack_flip_right
	; Flip attack and after effect to the right
	xor a
	; attack
	ld [$FE08 + 3], a
	ld [$FE0C + 3], a
	ld [$FE10 + 3], a
	ld [$FE14 + 3], a
	; after effect
	ld [$FE18 + 3], a
	ld [$FE1C + 3], a

.animate_attack_update_pos
	; Increase w_frame_counter_attack
	ld a, [w_frame_counter_attack]
	inc a
	ld [w_frame_counter_attack], a

	; Update Y position of attack animation
	ld a, [w_player_position_y]
	ld [$FE08], a ; top left
	ld [$FE0C], a ; top right
	add a, 8
	ld [$FE10], a ; bottom left
	ld [$FE14], a ; bottom right

	; Check if the attack is flipped, to position it on the right side of the player
	ld a, [$FE08 + 3]
	or a
	jr z, .animate_attack_update_pos_right

.animate_attack_update_pos_left
	; Update X position of attack animation
	ld a, [w_player_position_x]
	sub a, 8
	ld [$FE08 + 1], a ; top left
	ld [$FE10 + 1], a ; bottom left
	sub a, 8
	ld [$FE0C + 1], a ; top right
	ld [$FE14 + 1], a ; bottom right
	jp draw_attack.done

.animate_attack_update_pos_right
	; Update X position of attack animation
	ld a, [w_player_position_x]
	add a, 8
	ld [$FE08 + 1], a ; top left
	ld [$FE10 + 1], a ; bottom left
	add a, 8
	ld [$FE0C + 1], a ; top right
	ld [$FE14 + 1], a ; bottom right
	jp draw_attack.done


animate_after_effect::
	; Check if it's the 1st frame of after effect
	cp a, 6
	jr nz, .animate_after_effect_update_pos

	; Mask out the attack sprites
	xor a
	ld [$FE08], a ; top left
	ld [$FE0C], a ; top right
	ld [$FE10], a ; bottom left
	ld [$FE14], a ; bottom right
	ld [$FE08 + 1], a ; top left
	ld [$FE10 + 1], a ; bottom left
	ld [$FE0C + 1], a ; top right
	ld [$FE14 + 1], a ; bottom right

.animate_after_effect_update_pos
	; Increase w_frame_counter_attack
	ld a, [w_frame_counter_attack]
	inc a
	ld [w_frame_counter_attack], a

	; Update Y position of after effect animation
	ld a, [w_player_position_y]
	ld [$FE18], a ; left
	ld [$FE1C], a ; right

	; Check if the after effect is flipped, to position it on the right side of the player
	ld a, [$FE18 + 3]
	or a
	jr z, .animate_after_effect_update_pos_right

.animate_after_effect_update_pos_left
	; Update X position of attack animation
	ld a, [w_player_position_x]
	sub a, 8
	ld [$FE18 + 1], a ; left
	sub a, 8
	ld [$FE1C + 1], a ; right
	jp draw_attack.done

.animate_after_effect_update_pos_right
	; Update X position of attack animation
	ld a, [w_player_position_x]
	add a, 8
	ld [$FE18 + 1], a ; left
	add a, 8
	ld [$FE1C + 1], a ; right
	jp draw_attack.done


animate_attack_end::
	xor a

	; Reset attack vars
	ld [w_frame_counter_attack], a
	ld [w_player_attacking], a

	; Mask out after effect sprites
	ld [$FE18], a ; left
	ld [$FE1C], a ; right
	ld [$FE18 + 1], a ; left
	ld [$FE1C + 1], a ; right

	jp draw_attack.done


animate_jump::
	; Check if player is going up
	ld a, [w_player_jump_tracker]
	cp a, 2
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
	ld a, 1
	ld [$FE04 + 2], a
	jp draw_player.done

.animate_jump_falling
	ld a, 3
	ld [$FE04 + 2], a
	jp draw_player.done


animate_walk::
	; Check if current frame is idle, if yes jump right to animate_walk_update_frame
	ld a, [$FE04 + 2] ; $FE06 = 2nd OAMRAM spot's tile number
	cp a, 1
	jr z, .animate_walk_update_frame
	; Wait 10 frames before updating the walk animation
	ld a, [w_frame_counter_walk]
	inc a
	ld [w_frame_counter_walk], a
	cp a, 10 ; Every 10 frames, update the animation frame
	jr z, .animate_walk_update_frame
	jp draw_player.done ; Else, ret

.animate_walk_update_frame
	ld a, [$FE04 + 2]
	inc a
	cp a, 4
	jr nz, .animate_walk_update_sprite_index ; If still in range, set frame 1 or 2 of anim
	ld a, 2 ; Else, we're past the last index so set it back to first frame of anim

.animate_walk_update_sprite_index
	ld [$FE04 + 2], a

	; Reset the frame counter back to 0
	xor a
	ld [w_frame_counter_walk], a
	jp draw_player.done