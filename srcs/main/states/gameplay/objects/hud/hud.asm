INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"
INCLUDE "srcs/main/utils/tile_number_table.inc"
INCLUDE "srcs/main/utils/oam_number_table.inc"

SECTION "HudVariables", WRAM0
w_init_hud:			db
w_previous_masks:	db
w_previous_soul:	db

SECTION "Hud", ROM0

hud_tile_data: INCBIN "resources/sprites_hud.2bpp"
hud_tile_data_end:

initialize_hud::
	ld a, 1
	ld [w_init_hud], a
	ld a, 4
	ld [w_previous_masks], a
	ld a, 0
	ld [w_previous_soul], a

	; Copy the hud's tile data into VRAM
    ld de, hud_tile_data
    ld hl, HUD_TILES_START
    ld bc, hud_tile_data_end - hud_tile_data
    call copy_de_into_memory_at_hl

	; Set soul meter
	xor a
	ld b, a
	ld c, a
	ld d, T_SOUL_METER_EMPTY
	ld e, 0
	call RenderSimpleSprite

	; Set soul meter tail
	ld b, a
	ld c, a
	ld d, T_SOUL_METER_TAIL
	ld e, 0
	call RenderSimpleSprite

	; Set masks twice (4 masks)
	ld b, a
	ld c, a
	ld d, T_MASK2
	ld e, 0
	call RenderSimpleSprite

	ld b, a
	ld c, a
	ld d, T_MASK2
	ld e, 0
	call RenderSimpleSprite

	ret


update_hud::
	; Check if w_init_hud is 0, if it isn't it's the first time so we'll set the positions of all hud elements (won't change)
	ld a, [w_init_hud]
	or a
	jp nz, init_hud

	call update_masks
	call update_soul

	ret


update_masks:
	; Check if the player lost or gained a mask, if not we can ignore this part
	ld a, [w_previous_masks]
	ld b, a
	ld a, [w_player_masks]
	cp b
	ret z

	; w_player_masks is still stored in a
	cp 4
	jr nz, :+
	; Masks = 4
	ld a, T_MASK2
	ld [wShadowOAM + OAM_MASK_0 + 2], a
	ld [wShadowOAM + OAM_MASK_1 + 2], a
	ret
:
	ld a, [w_player_masks]
	cp 3
	jr nz, :+
	; Masks = 3
	ld a, T_MASK2
	ld [wShadowOAM + OAM_MASK_0 + 2], a
	ld a, T_MASK1
	ld [wShadowOAM + OAM_MASK_1 + 2], a
	ret
:
	ld a, [w_player_masks]
	cp 2
	jr nz, :+
	; Masks = 2
	ld a, T_MASK2
	ld [wShadowOAM + OAM_MASK_0 + 2], a
	ld a, T_MASK0
	ld [wShadowOAM + OAM_MASK_1 + 2], a
	ret
:
	ld a, [w_player_masks]
	cp 1
	jr nz, :+
	; Masks = 1
	ld a, T_MASK1
	ld [wShadowOAM + OAM_MASK_0 + 2], a
	ld a, T_MASK0
	ld [wShadowOAM + OAM_MASK_1 + 2], a
	ret
:
	; Masks = 0
	ld a, T_MASK0
	ld [wShadowOAM + OAM_MASK_0 + 2], a
	ld a, T_MASK0
	ld [wShadowOAM + OAM_MASK_1 + 2], a
	ret


update_soul:
	; Check if the player lost or gained soul, if not we can ignore this part
	ld a, [w_previous_soul]
	ld b, a
	ld a, [w_player_soul]
	cp b
	ret z

	; w_player_soul is still stored in a
	cp 99
	jr nz, :+
	; Soul = 99 (full)
	ld a, T_SOUL_METER_FULL
	ld [wShadowOAM + OAM_SOUL_METER + 2], a
	ret
:
	ld a, [w_player_soul]
	cp 66
	jr c, :+
	; Soul = 66 to 98
	ld a, T_SOUL_METER_HIGH
	ld [wShadowOAM + OAM_SOUL_METER + 2], a
	ret
:
	ld a, [w_player_soul]
	cp 33
	jr c, :+
	; Soul = 33 to 65
	ld a, T_SOUL_METER_LOW
	ld [wShadowOAM + OAM_SOUL_METER + 2], a
	ret
:
	; Soul = 0 to 32
	ld a, T_SOUL_METER_EMPTY
	ld [wShadowOAM + OAM_SOUL_METER + 2], a
	ret



; Used to set the positions of all hud elements (won't change)
init_hud:
	ld a, 18
	ld [wShadowOAM + OAM_SOUL_METER], a
	ld a, 10
	ld [wShadowOAM + OAM_SOUL_METER + 1], a
	ld a, 18
	ld [wShadowOAM + OAM_SOUL_METER_TAIL], a
	ld a, 18
	ld [wShadowOAM + OAM_SOUL_METER_TAIL + 1], a
	ld a, 22
	ld [wShadowOAM + OAM_MASK_0], a
	ld a, 21
	ld [wShadowOAM + OAM_MASK_0 + 1], a
	ld a, 22
	ld [wShadowOAM + OAM_MASK_1], a
	ld a, 29
	ld [wShadowOAM + OAM_MASK_1 + 1], a

	xor a
	ld [w_init_hud], a

	ret


player_gain_soul::
	; Check if w_player_soul is < MAX_SOUL + HIT_GAIN_SOUL (fe. 99 + 1 - 11 = 89), if it's higher, set w_player_soul to MAX_SOUL
	ld a, [w_player_soul]
	cp MAX_SOUL + 1 - HIT_GAIN_SOUL
	jr nc, :+

	; <
	add HIT_GAIN_SOUL
	ld [w_player_soul], a
	ret

:	; >=
	ld a, MAX_SOUL
	ld [w_player_soul], a
	ret