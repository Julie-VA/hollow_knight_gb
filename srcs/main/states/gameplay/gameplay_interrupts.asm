INCLUDE "srcs/main/utils/hardware.inc"

SECTION "VBlank Interrupt", ROM0[$0040]

vblank_interrupt:
	ld a, HIGH(wShadowOAM)
	call hOAMDMA

	reti

	; This is useful if we need to do something extensive during VBlank
	; push af
	; push bc
	; push de
	; push hl
	; jp vblank_handler


SECTION "VBlank Interrupt Function", ROM0

init_vblank_interrupt::
	; Enable VBlank interrupt
	ld a, IEF_VBLANK
	ldh [rIE], a

	; Clear CPU interrupt register
	xor a
	ldh [rIF], a

	; Globally enable interrupts
	ei
	ret


vblank_handler::
	; Now we just have to `pop` those registers and return!
	; pop hl
	; pop de
	; pop bc
	; pop af
	reti