INCLUDE "srcs/main/utils/hardware.inc"

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


SECTION "MathVariables", WRAM0
rand_state:: ds 4

SECTION "Math", ROM0

;; From: https://github.com/pinobatch/libbet/blob/master/src/rand.z80#L34-L54
; Generates a pseudorandom 16-bit integer in BC
; using the LCG formula from cc65 rand():
; x[i + 1] = x[i] * 0x01010101 + 0xB3B3B3B3
; @return A=B=state bits 31-24 (which have the best entropy),
; C=state bits 23-16, HL trashed
rand::
	; Add 0xB3 then multiply by 0x01010101
	ld hl, rand_state+0
	ld a, [hl]
	add a, $B3
	ld [hl+], a
	adc a, [hl]
	ld [hl+], a
	adc a, [hl]
	ld [hl+], a
	ld c, a
	adc a, [hl]
	ld [hl], a
	ld b, a
	ret
