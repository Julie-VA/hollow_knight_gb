INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "EnemiesVariables", WRAM0

w_enemies:: ds MAX_ENEMY_COUNT*PER_ENEMY_BYTES_COUNT

w_current_enemy::	dw

; w_enemy_1_active::		db
; w_enemy_1_position_x::	db
; w_enemy_1_position_y::	db
; w_enemy_1_health::		db
; w_enemy_1_type::		db

; w_enemy_1:: db 1, 136, 144, CRAWLID_HEALTH, CRAWLID
; w_enemy_2:: db 1, 16, 16, VENGEFLY_HEALTH, VENGEFLY


SECTION "Enemies", ROM0

enemies_tile_data: INCBIN "resources/sprites_enemies.2bpp"
enemies_tile_data_end:


initialize_enemies::
	; Copy the enemies' tile data into VRAM
    ld de, enemies_tile_data
    ld hl, ENEMIES_TILES_START
    ld bc, enemies_tile_data_end - enemies_tile_data
    call copy_de_into_memory_at_hl

	ld hl, w_enemies

	; Set active_byte
	ld a, 1
	ld [hli], a
	; Set y_byte
	ld a, 144
	ld [hli], a
	; Set x_byte
	ld a, 136
	ld [hli], a
	; Set health_byte
	ld a, CRAWLID_HEALTH
	ld [hli], a
	; Set type_byte
	ld a, CRAWLID
	ld [hli], a
	; Set end
	ld a, 1
	ld [hli], a

	; Set active_byte
	ld a, 1
	ld [hli], a
	; Set y_byte
	ld a, 32
	ld [hli], a
	; Set x_byte
	ld a, 48
	ld [hli], a
	; Set health_byte
	ld a, VENGEFLY_HEALTH
	ld [hli], a
	; Set type_byte
	ld a, VENGEFLY
	ld [hli], a
	; Set end
	xor a
	ld [hl], a

	; Set crawlid_l
	ld hl, w_enemies
	inc hl
	ld a, [hli]
	ld b, a
	ld a, [hl]
	ld c, a
	ld d, $10
	ld e, 0
	call RenderSimpleSprite

	; Set crawlid_r
	ld hl, w_enemies
	inc hl
	ld a, [hli]
	ld b, a
	ld a, [hl]
	add 8
	ld c, a
	ld d, $11
	ld e, 0
	call RenderSimpleSprite

	; Go to enemy 2
	ld hl, w_enemies
	ld a, l
    add PER_ENEMY_BYTES_COUNT
    ld l, a
    ld a, h
    adc 0
    ld h, a
	inc hl

	; Set vengefly_ul
	ld a, [hli]
	ld b, a
	ld a, [hl]
	ld c, a
	ld d, $12
	ld e, 0
	call RenderSimpleSprite
	dec hl

	; Set vengefly_ur
	ld a, [hli]
	ld b, a
	ld a, [hl]
	add 8
	ld c, a
	ld d, $13
	ld e, 0
	call RenderSimpleSprite
	dec hl

	; Set vengefly_dl
	ld a, [hli]
	add 8
	ld b, a
	ld a, [hl]
	ld c, a
	ld d, $14
	ld e, 0
	call RenderSimpleSprite
	dec hl

	; Set vengefly_dr
	ld a, [hli]
	add 8
	ld b, a
	ld a, [hl]
	add 8
	ld c, a
	ld d, $15
	ld e, 0
	call RenderSimpleSprite

	ret


update_enemies::
	call enemies_ai
	call draw_enemies
	ret


enemies_ai:
	ld hl, w_enemies

.enemies_ai_loop
	; Check if enemy is active
	ld a, [hl]
	or a
	jr z, .enemies_ai_loop_end

	; Save current enemy address in de
	ld d, h
	ld e, l

	; Check if enemy is a crawlid
	ld bc, enemy_type_byte
	add hl, bc
	ld a, [hl]
	cp a, CRAWLID
	jp z, crawlid_ai

	; Check if enemy is a Vengefly
	cp a, VENGEFLY
	call z, vengefly_ai

.enemies_ai_loop_end::
	; If enemy isn't active, go to enemy_end_byte to see if there's another enemy after and if we need to loop
	ld bc, enemy_end_byte
	add hl, bc
	ld a, [hl]
	or a
	ret z ; Ret if no more enemies
	inc hl ; Go to next enemy
	jr .enemies_ai_loop ; Jump to loop if more enemies


draw_enemies:
	ld hl, w_enemies
	inc hl
	; Update Y position in OAM
	ld a, [hli]
	ld [wShadowOAM + $38], a
	ld [wShadowOAM + $3C], a

	; Update X position in OAM
	ld a, [hl]
	ld [wShadowOAM + $38 + 1], a
	add 8
	ld [wShadowOAM + $3C + 1], a

	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	; Update y pos
	ld a, [hli]
	ld [wShadowOAM + $40], a
	ld [wShadowOAM + $44], a
	add 8
	ld [wShadowOAM + $48], a
	ld [wShadowOAM + $4C], a

	; Update x pos
	ld a, [hl]
	ld [wShadowOAM + $40 + 1], a
	ld [wShadowOAM + $48 + 1], a
	add 8
	ld [wShadowOAM + $44 + 1], a
	ld [wShadowOAM + $4C + 1], a

	ret