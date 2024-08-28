INCLUDE "srcs/main/utils/hardware.inc"

SECTION "SpriteVariables", WRAM0

w_sprites_used:: db

SECTION "Sprites", ROM0

clear_all_sprites:
	 
	; Start clearing oam
	xor a
    ld b, OAM_COUNT*sizeof_OAM_ATTRS ; 40 sprites times 4 bytes per sprite
    ld hl, wShadowOAM ; The start of our oam sprites in RAM

clear_oam_loop:
    ld [hli], a
    dec b
    jp nz, clear_oam_loop
    xor a
    ld [w_sprites_used], a
    
    
	; from: https://github.com/eievui5/gb-sprobj-lib
	; Finally, run the following code during VBlank:
	ld a, HIGH(wShadowOAM)
	jp hOAMDMA