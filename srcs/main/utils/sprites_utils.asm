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
