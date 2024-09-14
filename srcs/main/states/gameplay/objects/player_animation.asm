INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "PlayerAnimations", ROM0

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
	ld [$FE06], a
	ret

.animate_jump_falling
	ld a, 3
	ld [$FE06], a
	ret


animate_walking::
	; Check if current frame is idle, if yes jump right to animate_walking_update_frame
	ld a, [$FE06] ; $FE06 = 2nd OAMRAM spot's 
	cp a, 1
	jr z, .animate_walking_update_frame
	; Wait 10 frames before updating the walking animation
	ld a, [w_frame_counter]
	inc a
	ld [w_frame_counter], a
	cp a, 10 ; Every 10 frames, update the animation frame
	jr z, .animate_walking_update_frame
	ret ; Else, ret

.animate_walking_update_frame
	ld a, [$FE06]
	inc a
	cp a, 4
	jr nz, .animate_walking_update_sprite_index ; If still in range, set frame 1 or 2 of anim
	ld a, 2 ; Else, we're past the last index so set it back to first frame of anim

.animate_walking_update_sprite_index
	ld [$FE06], a

	; Reset the frame counter back to 0
	xor a
	ld [w_frame_counter], a
	ret