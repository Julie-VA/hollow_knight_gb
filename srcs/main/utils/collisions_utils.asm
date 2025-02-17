INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "Collisions", ROM0

; @param b: X position
; @param c: Y position
; Parameters are set by each direction function
; 1: Divide x position by 8 to get tile x position
; 2 (intuitive approach): Divide y position by 8 to get tile y position + Multiply tile y position by 32 then add tile x position to get position of the bg tile we're about to run into
; 2 (implemented): Set last 3 bits of y position to 0 (same as dividing since we multiply after), and multiply by 4 to get tile y position. Then add tile x position
; 3: Add $98 to high byte to get the tilemap address
; 4: Get tile number from tilemap address
check_collision_left_right::
	; Load x position in a
	ld a, b

	; Right shift 3 times to divide by 8 to get tile x position
	srl a
	srl a
	srl a
	ld e, a ; Store tile x position in e

	; Load y position of bottom tile in a
	ld a, c

	; Set the lower 3 bits to 0
	and a, ~7 ; = and a, ~00000111 = and a, 11111000

	; Multiply y position by 4 to get tile y position
	ld h, 0
	ld l, a
	add hl, hl
	add hl, hl

	; Add tile x position to get the full index
	ld a, l
	add e
	ld l, a

	; Add $98 to high byte h to get address from tilemap
	ld a, h
	add a, $98
	ld h, a

	; Get tile number from tilemap address
	ld a, [hl]

	; Check collision
	or a
	jr nz, .check_collision_left_right_hit

.check_collision_left_right_no_hit
	xor a
	ret

.check_collision_left_right_hit
	ld a, 1
	ret