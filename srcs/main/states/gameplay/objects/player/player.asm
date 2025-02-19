INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "PlayerVariables", WRAM0

w_player_position_x::		db
w_player_position_y::		db

w_player_jumping::			db
w_player_airborne::			db
w_player_velocity::			db
w_player_jump_strenght::	db
w_player_gravity_accu::		db ; The accumulator is used to travel by GRAVITY every GRAVITY_ACCU_MAX frames

w_player_attacking::		db ; 0 = not attacking, 1 = attacking right, 2 = left, 3 = up, 4 = down (see constants)


SECTION "PlayerCounters", WRAM0

w_player_counter_walk::		db
w_player_counter_attack::	db
w_player_counter_jump::		db ; Used to start the falling animation a bit later


SECTION "Player", ROM0

player_tile_data: INCBIN "resources/sprites_player.2bpp"
player_tile_data_end:


initialize_player::
	xor a
	ld [w_player_counter_walk], a
	ld [w_player_counter_attack], a
	ld [w_player_jumping], a
	ld [w_player_airborne], a
	ld [w_player_velocity], a
	ld [w_player_gravity_accu], a
	ld [w_player_counter_jump], a
	ld [w_player_attacking], a

	ld a, 152
    ld [w_player_position_x], a
	ld a, 136
    ld [w_player_position_y], a

    ; Copy the player's tile data into VRAM
    ld de, player_tile_data
    ld hl, PLAYER_TILES_START
    ld bc, player_tile_data_end - player_tile_data
    call copy_de_into_memory_at_hl

	; Set knight_top
	ld a, [w_player_position_y]
	ld b, a
	ld a, [w_player_position_x]
	ld c, a
	ld d, $00
	ld e, 0
	call RenderSimpleSprite

	; Set knight_bottom
	ld a, [w_player_position_y]
	add 8
	ld b, a
	ld a, [w_player_position_x]
	ld c, a
	ld d, $01
	ld e, 0
	call RenderSimpleSprite

	; Set slashes out of screen for later use
	; Set slash_1_x
	xor a
	ld b, a
	ld c, a
	ld d, $04
	ld e, a
	call RenderSimpleSprite
	; Set slash_2_x
	ld d, $05
	call RenderSimpleSprite
	; Set slash_3_x
	ld d, $06
	call RenderSimpleSprite
	; Set slash_4_x
	ld d, $07
	call RenderSimpleSprite

	; Set slash_after_effect_1_x
	ld d, $08
	call RenderSimpleSprite
	; Set slash_after_effect_2_x
	ld d, $09
	call RenderSimpleSprite

	; Set slash_1_y
	ld d, $0A
	call RenderSimpleSprite
	; Set slash_2_y
	ld d, $0B
	call RenderSimpleSprite
	; Set slash_3_y
	ld d, $0C
	call RenderSimpleSprite
	; Set slash_4_y
	ld d, $0D
	call RenderSimpleSprite

	; Set slash_after_effect_1_y
	ld d, $0E
	call RenderSimpleSprite
	; Set slash_after_effect_2_y
	ld d, $0F
	call RenderSimpleSprite

	ret


update_player::

.update_player_handle_input
	ld a, [w_cur_keys]
	and PADF_UP
	call nz, start_jump

	ld a, [w_player_jumping]
	or a
	call nz, cut_jump ; Call if player is jumping

    ld a, [w_cur_keys]
    and PADF_LEFT
    call nz, move_left

    ld a, [w_cur_keys]
    and PADF_RIGHT
    call nz, move_right

	ld a, [w_cur_keys]
	and (PADF_LEFT | PADF_RIGHT) ; Mask out left and right buttons
    or a
	call z, no_direction

	ld a, [w_cur_keys]
	and PADF_A
	call nz, attack

	ld a, [w_player_jumping]
	or a
	call nz, jump ; Call if player is jumping

	ld a, [w_player_jumping]
	or a
	call z, apply_gravity ; Call if player is not jumping

.update_player_draw
	call draw_player
	call draw_attack

	ret


draw_player:
	; Update Y position in OAM
	ld a, [w_player_position_y]
	ld [wShadowOAM], a
	add a, 8
	ld [wShadowOAM + $04], a

	; Update X position in OAM
	ld a, [w_player_position_x]
	ld [wShadowOAM + 1], a
	ld [wShadowOAM + $04 + 1], a

	; Check if player is jumping or airborne, if so animate jump
	ld a, [w_player_jumping]
	ld hl, w_player_airborne
	or a, [hl]
	jp nz, animate_jump

	; Check if player is moving left or right, if so animate walk
	ld a, [w_cur_keys]
	and (PADF_LEFT | PADF_RIGHT)
	or a
	jp nz, animate_walk

.done::
	ret


draw_attack:
	; Check if player is attacking
	ld a, [w_player_attacking]
	or a
	ret z

	ld a, [w_player_counter_attack]
	cp AFTER_EFFECT_TIME + 1 ; Check if we're past the attack animation
	jr c, .draw_attack_animate
	cp ATTACK_COOLDOWN + 1 ; Check if we're past the cooldown
	jr c, .done

	; Reset attack vars
	xor a
	ld [w_player_counter_attack], a
	ld [w_player_attacking], a
	ret

.draw_attack_animate
	; Check if we're animating the first part of the attack
	cp ATTACK_TIME
	jp c, animate_attack

	; Check if we're animating the attack's after effect
	cp AFTER_EFFECT_TIME
	jp c, animate_after_effect

	; If both checks failed, it's the end so we can end the attack
	jp animate_attack_end

.done::
	; Increase w_player_counter_attack
	ld a, [w_player_counter_attack]
	inc a
	ld [w_player_counter_attack], a
	ret
