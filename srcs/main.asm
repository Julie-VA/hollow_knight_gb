INCLUDE "utils/hardware.inc"
INCLUDE "utils/utils.asm"

SECTION "Header", ROM0[$100]

	jp EntryPoint

	ds $150 - @, 0 ; Make room for the header

EntryPoint:
	; Do not turn the LCD off outside of VBlank

WaitVBlank:
	call wait_vblank

	call turn_off_lcd

	; Copy the Knight tile in memory
	ld de, KnightTileData
	ld hl, $8000
	ld bc, KnightTileDataEnd - KnightTileData
	call Memcopy

	call clear_oam

	; Set knight_top
	ld hl, _OAMRAM
	ld a, 128 + 16
	ld [hli], a
	ld a, 16 + 8
	ld [hli], a
	xor a
	ld [hli], a
	ld [hl], a

	; Set knight_bottom
	ld hl, _OAMRAM + 4
	ld a, 136 + 16
	ld [hli], a
	ld a, 16 + 8
	ld [hli], a
	ld a, 1
	ld [hli], a
	xor a
	ld [hl], a

	ld a, LCDCF_ON | LCDCF_OBJON
	call turn_on_lcd

	; During the first (blank) frame, initialize display registers
	ld a, %11100100
	ld [rBGP], a ; Display register
	ld a, %11100100
	ld [rOBP0], a ; Object register 0

	; Initialize global variables
	xor a
	ld [wFrameCounter], a
	ld [wCurKeys], a
	ld [wNewKeys], a

Main:
	; We need to make sure we wait for VBlank to be done before moving on to the next frame
	call wait_not_vblank

WaitVBlank2:
	;Then we can wait for VBlank before making any changes
	call wait_vblank

	; Check the current keys every frame and move left or right.
	call UpdateKeys

	; First, check if the left button is pressed.
CheckLeft:
	ld a, [wCurKeys]
	and a, PADF_LEFT
	jp z, CheckRight
Left:
	; Flip knight_top
	ld a, %00100000
	ld [_OAMRAM + 3], a
	; Move the knight_top one pixel to the left. OAMRAM + 1 bc we move X, OAMRAM is Y
	ld a, [_OAMRAM + 1]
	dec a
	ld [_OAMRAM + 1], a
	; Flip knight_bottom
	ld a, %00100000
	ld [_OAMRAM + 7], a
	; Move the knight_bottom one pixel to the right.
	ld a, [_OAMRAM + 5]
	dec a
	ld [_OAMRAM + 5], a

	; Update walking animation frame
	; Check if current frame is idle, if yes jump right to update_frame
	ld a, [$FE06]
	cp a, 1
	jr z, .update_frame
	; Wait 10 frames before updating the walking animation
	ld a, [wFrameCounter]
	inc a
	ld [wFrameCounter], a
	cp a, 10 ; Every 10 frames, update the frame
	jr z, .update_frame
	jp Main ; Else, go back to main

.update_frame
	ld a, [$FE06]
	inc a
	cp a, 4
	jr nz, .update_sprite_index ; If still in range, set frame 1 or 2 of anim
	ld a, 2 ; Else, we're past the last index so set it back to first frame of anim
.update_sprite_index
	ld [$FE06], a

	; Reset the frame counter back to 0
	xor a
	ld [wFrameCounter], a
	jp Main

; Then check the right button.
CheckRight:
	ld a, [wCurKeys]
	and a, PADF_RIGHT
	jp z, Main
Right:
	; Flip knight_top
	xor a
	ld [_OAMRAM + 3], a
	; Move the Knight1 one pixel to the right. OAMRAM + 1 bc we move X, OAMRAM is Y
	ld a, [_OAMRAM + 1]
	inc a
	ld [_OAMRAM + 1], a
	; Flip knight_bottom
	xor a
	ld [_OAMRAM + 7], a
	; Move the knight_bottom one pixel to the right.
	ld a, [_OAMRAM + 5]
	inc a
	ld [_OAMRAM + 5], a

	; Update walking animation frame
	; Check if current frame is idle, if yes jump right to update_frame
	ld a, [$FE06]
	cp a, 1
	jr z, .update_frame
	; Wait 10 frames before updating the walking animation
	ld a, [wFrameCounter]
	inc a
	ld [wFrameCounter], a
	cp a, 10 ; Every 10 frames, update the animation frame
	jr z, .update_frame
	jp Main ; Else, go back to main

.update_frame
	ld a, [$FE06]
	inc a
	cp a, 4
	jr nz, .update_sprite_index ; If still in range, set frame 1 or 2 of anim
	ld a, 2 ; Else, we're past the last index so set it back to first frame of anim
.update_sprite_index
	ld [$FE06], a

	; Reset the frame counter back to 0
	xor a
	ld [wFrameCounter], a
	jp Main

; Copy bytes from one area to another.
; @param de: Source
; @param hl: Destination
; @param bc: Length
Memcopy:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, Memcopy
	ret

UpdateKeys:
  ; Poll half the controller
  ld a, P1F_GET_BTN
  call .onenibble
  ld b, a ; B7-4 = 1; B3-0 = unpressed buttons

  ; Poll the other half
  ld a, P1F_GET_DPAD
  call .onenibble
  swap a ; A3-0 = unpressed directions; A7-4 = 1
  xor a, b ; A = pressed buttons + directions
  ld b, a ; B = pressed buttons + directions

  ; And release the controller
  ld a, P1F_GET_NONE
  ldh [rP1], a

  ; Combine with previous wCurKeys to make wNewKeys
  ld a, [wCurKeys]
  xor a, b ; A = keys that changed state
  and a, b ; A = keys that changed to pressed
  ld [wNewKeys], a
  ld a, b
  ld [wCurKeys], a
  ret

.onenibble
  ldh [rP1], a ; switch the key matrix
  call .knownret ; burn 10 cycles calling a known ret
  ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
  ldh a, [rP1]
  ldh a, [rP1] ; this read counts
  or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
.knownret
  ret

KnightTileData: INCBIN "resources/knight_sprites.2bpp"
KnightTileDataEnd:

SECTION "Counter", WRAM0
wFrameCounter: db

SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db