INCLUDE "srcs/main/utils/hardware.inc"

SECTION "VBlankVariables", WRAM0

w_vblank_count:: db

SECTION "VBlank functions", ROM0

wait_vblank::
	ld a, [rLY]
	cp 144
	jr c, wait_vblank
	ret

wait_not_vblank::
	ld a, [rLY]
	cp 144
	jr nc, wait_not_vblank
	ret


SECTION "Background functions", ROM0

clear_background_tilemap::
	; Turn off LCD
	xor a
	ld [rLCDC], a

	ld bc, 1024
	ld hl, $9800

.clear_background_tilemap_loop:
	xor a
	ld [hli], a
	dec bc
	ld a, b
	or c
	jp nz, .clear_background_tilemap_loop

	; Turn on LCD
	ld a, LCDCF_ON  | LCDCF_BGON|LCDCF_OBJON | LCDCF_OBJ16
	ld [rLCDC], a

	ret


clear_title_screen_tiles::
	; Turn off LCD
	xor a
	ld [rLCDC], a

	ld bc, 2960
	ld hl, $8800

.clear_title_screen_tiles_loop:
	xor a
	ld [hli], a
	dec bc
	ld a, b
	or c
	jp nz, .clear_title_screen_tiles_loop

	; Turn on LCD
	ld a, LCDCF_ON  | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16
	ld [rLCDC], a

	ret


SECTION "Interrupts", ROM0

disable_interrupts::
	xor a
	ldh [rSTAT], a
	di
	ret


SECTION "Memory functions", ROM0

; @param de: Source
; @param hl: Destination
; @param bc: Length
copy_de_into_memory_at_hl::
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or c
	jp nz, copy_de_into_memory_at_hl
	ret


; @param de: Source
; @param hl: Destination
; @param bc: Length
copy_de_into_memory_at_hl_with_52_offset::
	ld a, [de]
	add a, 52
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or c
	jp nz, copy_de_into_memory_at_hl_with_52_offset
	ret
