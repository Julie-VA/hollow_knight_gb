INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"
INCLUDE "srcs/main/utils/hUGEDriver/hUGE.inc"

; SFX (place in .inc file)
DEF	rAUD1LEN_lowb	EQU	$11
DEF	rAUD1ENV_lowb	EQU $12
DEF	rAUD1LOW_lowb	EQU $13
DEF	rAUD1HIGH_lowb	EQU $14
DEF	rAUD4LEN_lowb	EQU $20
DEF	rAUD4ENV_lowb	EQU $21
DEF	rAUD4POLY_lowb	EQU $22
DEF	rAUD4GO_lowb	EQU $23
DEF	SFX_NEXT		EQU 1
DEF	SFX_END			EQU 0
DEF	sBITCOUNTEROFF	EQU 0
DEF	sBITCOUNTERON	EQU 1

SECTION "SFX Tables", ROMX

; Format: db -> low byte of register (all audio registers start with $FF), value
SFX_sword_1::
    db rAUD4LEN_lowb, 0				; length 0 and stays 0

    db rAUD4ENV_lowb, %10110000				; 1011: volume = 11 | 0: decrease | 000: change = 0
    db rAUD4POLY_lowb, D_8, sBITCOUNTEROFF
    db rAUD4GO_lowb, %10000000				; trigger

	db rAUD4ENV_lowb, %10010000				; 1001: volume = 9 | 0: decrease | 000: change = 0
    db rAUD4POLY_lowb, C_8, sBITCOUNTEROFF
    db rAUD4GO_lowb, %10000000				; trigger

	db rAUD4ENV_lowb, %10000000				; 1000: volume = 8 | 0: decrease | 000: change = 0
    db rAUD4POLY_lowb, A#7, sBITCOUNTEROFF
    db rAUD4GO_lowb, %10000000				; trigger

	db rAUD4ENV_lowb, %01100000				; 0110: volume = 6 | 0: decrease | 000: change = 0
    db rAUD4POLY_lowb, G#7, sBITCOUNTEROFF
    db rAUD4GO_lowb, %10000000				; trigger

	db rAUD4ENV_lowb, %01100000				; 0110: volume = 6 | 0: decrease | 000: change = 0
    db rAUD4POLY_lowb, C#7, sBITCOUNTERON
    db rAUD4GO_lowb, %10000000				; trigger

	db rAUD4ENV_lowb, %01100000				; 0110: volume = 6 | 0: decrease | 000: change = 0
    db rAUD4POLY_lowb, A#6, sBITCOUNTERON
    db rAUD4GO_lowb, %10000000				; trigger

	db rAUD4ENV_lowb, %01100000				; 0110: volume = 6 | 0: decrease | 000: change = 0
    db rAUD4POLY_lowb, G#6, sBITCOUNTERON
    db rAUD4GO_lowb, %10000000				; trigger

	db rAUD4ENV_lowb, %00000000				; 0000: volume = 0 | 0: decrease | 000: change = 0
	; db rAUD4POLY_lowb, 90, sBITCOUNTEROFF
    ; db rAUD4GO_lowb, %00000000				; trigger
    db SFX_END


SECTION "SFX Functions", ROM0

play_sfx::
	ld hl, SFX_sword_1

.play_sfx_next_register:
	ld a, [hli]		; Load audio register

	cp SFX_END
	jr z, .play_sfx_done

	cp rAUD4POLY_lowb
	jr z, .play_sfx_polynomial_counter

.play_sfx_normal_case:
	ld b, $FF	; Load high byte of reg into b
	ld c, a		; Load low byte of reg into c
	ld a, [hli]	; Load note to put into reg
	ld [bc], a	; Load note into reg

	ld a, c
	cp rAUD4GO_lowb
	jr nz, .play_sfx_next_register

	halt

	jr .play_sfx_next_register

; If the register is rAUD4POLY, calculate the note's polynomial counter thanks to hUGEDriver's function
.play_sfx_polynomial_counter:
	ld d, a				; Save rAUD4POLY_lowb
	ld a, [hli]			; Load hUGETracker note
	
	push hl
	call get_note_poly
	pop hl

	; Check if 7BITCOUNTER is on or off
	ld e, a		; Save get_note_poly output
	ld a, [hli]	; Load 7BITCOUNTER
	cp sBITCOUNTEROFF
	jr z, .polynomial_counter_load_note

	; If it's on, adjust note's 3rd bit
	ld a, e
	set 3, a

.polynomial_counter_load_note:
	ld b, $FF			; Load high byte of reg into b
	ld c, d				; Load low byte of reg into c
	ld [bc], a			; Load note into reg
	jr .play_sfx_next_register

.play_sfx_done:
	ret




