INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "CollisionUtilsVariables", WRAM0
w_size::			db
w_object1_value::	db
w_object2_value::	db

SECTION "Collisions", ROM0

; @param b: X position
; @param c: Y position
; Parameters are set by each direction function
; 1: Divide x position by 8 to get tile x position
; 2 (intuitive approach): Divide y position by 8 to get tile y position + Multiply tile y position by 32 then add tile x position to get position of the bg tile we're about to run into
; 2 (implemented): Set last 3 bits of y position to 0 (same as dividing since we multiply after), and multiply by 4 to get tile y position. Then add tile x position
; 3: Add $98 to high byte to get the tilemap address
; 4: Get tile number from tilemap address
check_collision_wall::
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

	; Get tile number from tilemap address (wait for VRAM to be ready for read first)
	:ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, :-
	ld a, [hl]

	; Check collision
	or a
	jr nz, .hit

.no_hit
	xor a
	ret

.hit
	ld a, 1
	ret


; The easiest way to check for overlap, is to check the difference bewteen their centers. If the absolute value of their x & y differences
; are BOTH smaller than the sum of their half widths, we have a collision. (From https://gbdev.io/gb-asm-tutorial/part3/collision.html)
; SizeX = Obj1 half width + Obj2 half width | SizeY = Obj1 half height + Obj2 half height
; ABS(Obj1.x - Obj2.x) > SizeX AND/OR ABS(Obj1.y - Obj2.y) > SizeY == No collision
; ABS(Obj1.x - Obj2.x) < SizeX AND ABS(Obj1.y - Obj2.y) < SizeY == Collision
check_object_position_difference::
	ld a, [w_object1_value]
	ld b, a
	ld a, [w_object2_value]
	ld c, a
	ld a, [w_size]
	ld d, a

	; Substract Obj2(c) - (Obj1 + Size)(b)
	; Carry means b < c, so Obj1 is visually above or to the left of Obj2
	ld a, b
	add d
	cp c
	jr c, .failure

	; Substract Obj2(c) - (Obj1 - Size)(b)
	; No carry means b > c, so Obj1 is visually under or to the right of Obj2
	ld a, b
	sub d
	cp c
	jr nc, .failure

	ld a, 1
	ret

.failure
	xor a
	ret