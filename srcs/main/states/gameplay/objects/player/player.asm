INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"
INCLUDE "srcs/main/utils/tile_number_table.inc"

SECTION "PlayerVariables", WRAM0

w_player_position_x::		db
w_player_position_y::		db

w_player_jumping::			db
w_player_airborne::			db
w_player_velocity::			db
w_player_jump_strenght::	db
w_player_gravity_accu::		db ; The accumulator is used to travel by GRAVITY every GRAVITY_ACCU_MAX frames

w_player_attacking::		db ; 0 = not attacking, 1 = attacking right, 2 = left, 3 = up, 4 = down (see constants)
w_player_last_attack::		db ; 0 = SFX_sword_1, 1 = SFX_sword_2. Used to alternate when attacking in succession


SECTION "PlayerCounters", WRAM0

w_player_counter_walk::				db
w_player_counter_attack::			db
w_player_counter_followupattack::	db ; Used to play another SFX if swings are one after another
w_player_counter_jump::				db ; Used to start the falling animation a bit later


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
	ld d, PLAYER_TOP
	ld e, 0
	call RenderSimpleSprite

	; Set knight_bottom
	ld a, [w_player_position_y]
	add 8
	ld b, a
	ld a, [w_player_position_x]
	ld c, a
	ld d, PLAYER_BOT_IDLE
	ld e, 0
	call RenderSimpleSprite

	; Set slashes out of screen for later use
	; Set slash_1_x
	xor a
	ld b, a
	ld c, a
	ld d, SLASH_1_X
	ld e, a
	call RenderSimpleSprite
	; Set slash_2_x
	ld d, SLASH_2_X
	call RenderSimpleSprite
	; Set slash_3_x
	ld d, SLASH_3_X
	call RenderSimpleSprite
	; Set slash_4_x
	ld d, SLASH_4_X
	call RenderSimpleSprite

	; Set slash_after_effect_1_x
	ld d, SLASH_AFTER_EFFECT_1_X
	call RenderSimpleSprite
	; Set slash_after_effect_2_x
	ld d, SLASH_AFTER_EFFECT_2_X
	call RenderSimpleSprite

	; Set slash_1_y
	ld d, SLASH_1_Y
	call RenderSimpleSprite
	; Set slash_2_y
	ld d, SLASH_2_Y
	call RenderSimpleSprite
	; Set slash_3_y
	ld d, SLASH_3_Y
	call RenderSimpleSprite
	; Set slash_4_y
	ld d, SLASH_4_Y
	call RenderSimpleSprite

	; Set slash_after_effect_1_y
	ld d, SLASH_AFTER_EFFECT_1_Y
	call RenderSimpleSprite
	; Set slash_after_effect_2_y
	ld d, SLASH_AFTER_EFFECT_2_Y
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


; Used to increase the followup window counter after an attack, so in case a 2nd swing happens in the ATTACK_FOLLOWUP_WINDOW frames following the 1st one, another SFX plays
.update_player_attack_counter
	ld a, [w_player_attacking]
	or a
	jr nz, .update_player_draw ; If player is attacking, w_player_counter_followupattack doesn't need to change

	ld a, [w_player_counter_followupattack]
	or a
	jr z, .update_player_draw ; If counter is at 0, we're not in the followup window

	cp ATTACK_FOLLOWUP_WINDOW + 1 ; Check if we're past the followup window
	jr nc, :+ ; If we are, reset counter and continue with update_player

	; Otherwise, increase counter
	ld a, [w_player_counter_followupattack]
	inc a
	ld [w_player_counter_followupattack], a
	jr .update_player_draw

:
	xor a
	ld [w_player_counter_followupattack], a


.update_player_draw
	call draw_player
	call draw_attack


.update_player_sfx
	call attack_sfx

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
	; Check if player is attacking, if so, update player_bottom sprite to not include sword
	ld a, [w_player_attacking]
	or a
	ret z
	ld a, [wShadowOAM + $04 + 2]
	cp PLAYER_BOT_IDLE_ATK ; If we're past the animations including the sword, do not add 3. The following flag checks do a >= PLAYER_BOT_IDLE_ATK
	jr z, :+ ; If z is set, a == PLAYER_BOT_IDLE_ATK
	jr nc, :+ ; If c is not set, a > PLAYER_BOT_IDLE_ATK
	add 3
	: ld [wShadowOAM + $04 + 2], a

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
	ld a, 1
	ld [w_player_counter_followupattack], a
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


attack_sfx:
	; Check if player is attacking
	ld a, [w_player_attacking]
	or a
	ret z

	; Check if sound effect needs to be started.
	ld a, [w_player_counter_attack]
	dec a ; cp 1, if w_player_counter_attack = 1 then we just started an attack
	jr nz, .attack_sfx_continue

; If we just started an attack, check if it's a new one or one in the followup window
.attack_sfx_choose_sfx
	ld a, [w_player_counter_followupattack]
	or a
	jr z, .attack_sfx_sword_1 ; If it's not an attack in the followup window, init SFX_sword_1

	ld a, [w_player_last_attack]
	or a
	jr z, .attack_sfx_sword_2 ; If last attack was SFX_sword_1, init SFX_sword 2

.attack_sfx_sword_1
	ld hl, SFX_sword_1
	xor a
	ld [w_player_last_attack], a ; Set last attack as SFX_sword_1
	jr .attack_sfx_init

.attack_sfx_sword_2
	ld hl, SFX_sword_2
	ld a, 1
	ld [w_player_last_attack], a ; Set last attack as SFX_sword_2

.attack_sfx_init
	call sfx_init

; Continue playing sound effect
.attack_sfx_continue
	call sfx_dosound

	ret
