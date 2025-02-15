INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "EnemiesVariables", WRAM0

w_enemy_1_active::		db
w_enemy_1_position_x::	db
w_enemy_1_position_y::	db
w_enemy_1_type::		db
w_enemy_1_health::		db

w_enemy_1_accu::		db

w_enemy_2_active::		db
w_enemy_2_position_x::	db
w_enemy_2_position_y::	db
w_enemy_2_type::		db
w_enemy_2_health::		db

w_enemy_2_accu::		db

; Method using a certain amount of continuous bytes for all enemies. w_current_enemy allows us to easily store the position of the current enemy in these blocks of bytes.
; w_enemies:: ds MAX_ENEMY_COUNT*PER_ENEMY_BYTES_COUNT
; w_current_enemy::	dw

; Other method but I don't see the point of this compared to the clarity of the separate variables right now. Useful for initializing since it's contiguous memory.
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

	; Set active_byte
	ld a, 1
	ld [w_enemy_1_active], a
	; Set y_byte
	ld a, 144
	ld [w_enemy_1_position_y], a
	; Set x_byte
	ld a, 104
	ld [w_enemy_1_position_x], a
	; Set type_byte
	ld a, CRAWLID
	ld [w_enemy_1_type], a
	; Set health_byte
	ld a, CRAWLID_HEALTH
	ld [w_enemy_1_health], a
	xor a
	ld [w_enemy_1_accu], a

	; Set active_byte
	ld a, 1
	ld [w_enemy_2_active], a
	; Set y_byte
	ld a, 32
	ld [w_enemy_2_position_y], a
	; Set x_byte
	ld a, 48
	ld [w_enemy_2_position_x], a
	; Set type_byte
	ld a, VENGEFLY
	ld [w_enemy_2_type], a
	; Set health_byte
	ld a, VENGEFLY_HEALTH
	ld [w_enemy_2_health], a
	xor a
	ld [w_enemy_2_accu], a

	; Set crawlid_l
	ld a, [w_enemy_1_position_y]
	ld b, a
	ld a, [w_enemy_1_position_x]
	ld c, a
	ld d, $10
	ld e, 0
	call RenderSimpleSprite

	; Set crawlid_r
	ld a, [w_enemy_1_position_y]
	ld b, a
	ld a, [w_enemy_1_position_x]
	add 8
	ld c, a
	ld d, $11
	ld e, 0
	call RenderSimpleSprite

	; Set vengefly_ul
	ld a, [w_enemy_2_position_y]
	ld b, a
	ld a, [w_enemy_2_position_x]
	ld c, a
	ld d, $12
	ld e, 0
	call RenderSimpleSprite
	dec hl

	; Set vengefly_ur
	ld a, [w_enemy_2_position_y]
	ld b, a
	ld a, [w_enemy_2_position_x]
	add 8
	ld c, a
	ld d, $13
	ld e, 0
	call RenderSimpleSprite
	dec hl

	; Set vengefly_dl
	ld a, [w_enemy_2_position_y]
	add 8
	ld b, a
	ld a, [w_enemy_2_position_x]
	ld c, a
	ld d, $14
	ld e, 0
	call RenderSimpleSprite
	dec hl

	; Set vengefly_dr
	ld a, [w_enemy_2_position_y]
	add 8
	ld b, a
	ld a, [w_enemy_2_position_x]
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
	ld a, [w_enemy_1_position_x]
	ld b, a
	; Check if enemy_1 is active
	ld a, [w_enemy_1_active]
	or a
	call nz, crawlid_ai
	ld a, b
	ld [w_enemy_1_position_x], a

	; Check if enemy_2 is active
	ld a, [w_enemy_2_active]
	or a
	call nz, vengefly_ai

	ret

draw_enemies:
	; Update enemy_1 position
	; Update Y position in OAM
	ld a, [w_enemy_1_position_y]
	ld [wShadowOAM + $38], a
	ld [wShadowOAM + $3C], a

	; Check what direction we're going first
	ld a, [wShadowOAM + $38 + 3]
	and %00100000 ; Only the x flip bit is useful for this
	cp %00100000
	jr z, .draw_enemies_right
.draw_enemies_left
	; Update X position in OAM
	ld a, [w_enemy_1_position_x]
	dec a ; Needed because position reflects the nose of crawlid and there's one blank pixel
	ld [wShadowOAM + $38 + 1], a
	add 8
	ld [wShadowOAM + $3C + 1], a
	jr .draw_enemies_cont
.draw_enemies_right
	; Update X position in OAM
	ld a, [w_enemy_1_position_x]
	inc a
	ld [wShadowOAM + $38 + 1], a
	sub 8
	ld [wShadowOAM + $3C + 1], a

.draw_enemies_cont
	; Update enemy_2 position
	; Update y pos
	ld a, [w_enemy_2_position_y]
	ld [wShadowOAM + $40], a
	ld [wShadowOAM + $44], a
	add 8
	ld [wShadowOAM + $48], a
	ld [wShadowOAM + $4C], a

	; Update x pos
	ld a, [w_enemy_2_position_x]
	ld [wShadowOAM + $40 + 1], a
	ld [wShadowOAM + $48 + 1], a
	add 8
	ld [wShadowOAM + $44 + 1], a
	ld [wShadowOAM + $4C + 1], a

	ret