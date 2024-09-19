INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "SpriteVariables", WRAM0

w_last_oam_address:: dw
w_sprites_used:: db

SECTION "Sprites", ROM0

clear_oam::
	xor a
    ld b, OAM_COUNT*sizeof_OAM_ATTRS ; 40 sprites times 4 bytes per sprite
    ld hl, wShadowOAM ; The start of our oam sprites in RAM

clear_oam_loop:
    ld [hli], a
    dec b
    jp nz, clear_oam_loop
    xor a
    ld [w_sprites_used], a

	; Finally, run the following code during VBlank:
	ld a, HIGH(wShadowOAM)
	jp hOAMDMA


clear_remaining_sprites::
    ; Get our offset address in hl
	ld a,[w_last_oam_address]
    ld l, a
	ld a, HIGH(wShadowOAM)
    ld h, a

    ld a, l
    cp 160
    ret nc

    ; Set the y and x to be 0
    xor a
    ld [hli], a
    ld [hld], a

    ; Move up 4 bytes
    ld a, l
    add 4
    ld l, a

    call next_oam_sprite

    jp clear_remaining_sprites


reset_oam_sprite_address::
    xor a
    ld [w_sprites_used], a

	ld a, LOW(wShadowOAM)
	ld [w_last_oam_address], a
	ld a, HIGH(wShadowOAM)
	ld [w_last_oam_address + 1], a

    ret


next_oam_sprite::
    ld a, [w_sprites_used]
    inc a
    ld [w_sprites_used], a

	ld a,[w_last_oam_address]
    add sizeof_OAM_ATTRS
	ld [w_last_oam_address], a
	ld a, HIGH(wShadowOAM)
	ld [w_last_oam_address + 1], a

    ret
