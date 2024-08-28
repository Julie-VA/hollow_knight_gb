INCLUDE "srcs/main/utils/hardware.inc"

DEF GRAVITY			EQU 1
DEF JUMP_STRENGHT	EQU -10

SECTION "Functions", ROM0

wait_vblank:
	ld a, [rLY]
	cp 144
	jr c, wait_vblank
	ret

wait_not_vblank:
	ld a, [rLY]
	cp 144
	jr nc, wait_not_vblank
	ret

turn_off_lcd:
	xor a ; ld a, 0
	ld [rLCDC], a
	ret

; @param a: byte containing info about what display(s) to turn on
turn_on_lcd:
	ld [rLCDC], a
	ret

set_default_palette:
	ld a, %11100100
	ld [rBGP], a
	ld [rOBP0], a
	ret

; Copy bytes from one area to another.
; @param de: Source
; @param hl: Destination
; @param bc: Length
mem_copy:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, mem_copy
	ret

; fill the screen with the tile at address in register b
fill_screen:
	ld hl, _SCRN0
.clear
	ld a, b
	ld [hli], a
	ld a, h
	cp $9C ; screen ends at $9C00
	jr nz, .clear
	ret

clear_oam:
	ld hl, _OAMRAM
.clear
	xor a
	ld [hli], a
	ld a, h
	cp $FF ; OAMRAM ends at $FF00
	jr nz, .clear
	ret