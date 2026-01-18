INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"
INCLUDE "srcs/main/utils/tile_number_table.inc"
INCLUDE "srcs/main/utils/oam_number_table.inc"

SECTION "Hud", ROM0

hud_tile_data: INCBIN "resources/sprites_hud.2bpp"
hud_tile_data_end:

initialize_hud::
	; Copy the hud's tile data into VRAM
    ld de, hud_tile_data
    ld hl, HUD_TILES_START
    ld bc, hud_tile_data_end - hud_tile_data
    call copy_de_into_memory_at_hl

	; Set soul meter
	xor a
	ld b, a
	ld c, a
	ld d, T_SOUL_METER_HIGH
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
	ld d, T_MASK1
	ld e, 0
	call RenderSimpleSprite

	ret


update_hud::
	call draw_hud


draw_hud:
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
	ld a, 22
	ld [wShadowOAM + OAM_MASK_0 + 1], a
	ld a, 22
	ld [wShadowOAM + OAM_MASK_1], a
	ld a, 30
	ld [wShadowOAM + OAM_MASK_1 + 1], a

	ret

