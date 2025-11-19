INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"
INCLUDE "srcs/main/utils/hUGE.inc"

SECTION "SFX Tables", ROMX

; Format: db -> low byte of register (all audio registers start with $FF), value
SFX_sword_1::
    db rAUD4LEN_lowb, 0				; length 0 and stays 0

    db rAUD4ENV_lowb, %10110000		; 1011: volume = 11 | 0: decrease | 000: change = 0
    db rAUD4POLY_lowb, D_8
    db rAUD4GO_lowb, %10000000		; trigger
	db SFX_NEXT
	db rAUD4ENV_lowb, %10010000		; 1001: volume = 9 | 0: decrease | 000: change = 0
    db rAUD4POLY_lowb, C_8
    db rAUD4GO_lowb, %10000000		; trigger
	db SFX_NEXT
	db rAUD4ENV_lowb, %10000000		; 1000: volume = 8 | 0: decrease | 000: change = 0
    db rAUD4POLY_lowb, A#7
    db rAUD4GO_lowb, %10000000		; trigger
	db SFX_NEXT
	db rAUD4ENV_lowb, %01100000		; 0110: volume = 6 | 0: decrease | 000: change = 0
    db rAUD4POLY_lowb, G#7
    db rAUD4GO_lowb, %10000000		; trigger
	db SFX_NEXT
	db rAUD4ENV_lowb, %01100000		; 0110: volume = 6 | 0: decrease | 000: change = 0
    db rAUD4POLY_lowb, C#7
    db rAUD4GO_lowb, %10000000		; trigger
	db SFX_NEXT
	db rAUD4ENV_lowb, %01100000		; 0110: volume = 6 | 0: decrease | 000: change = 0
    db rAUD4POLY_lowb, A#6
    db rAUD4GO_lowb, %10000000		; trigger
	db SFX_NEXT
	db rAUD4ENV_lowb, %01100000		; 0110: volume = 6 | 0: decrease | 000: change = 0
    db rAUD4POLY_lowb, G#6
    db rAUD4GO_lowb, %10000000		; trigger
	db SFX_NEXT
	db rAUD4ENV_lowb, %00000000		; 0000: volume = 0 | 0: decrease | 000: change = 0
	db rAUD4POLY_lowb, 90
    db rAUD4GO_lowb, %10000000		; trigger
    db SFX_END


SECTION "SFX Functions", ROM0

play_sfx::
	ld hl, SFX_sword_1

.play_sfx_next_register:
	ld a, [hli]		; Load audio register

	cp SFX_END
	jr z, .play_sfx_done

	cp SFX_NEXT
	jr nz, .next
	halt
.next

	cp rAUD4POLY_lowb
	jr z, .play_sfx_polynomial_counter

.play_sfx_normal_case:
	ld b, $FF	; Load high byte of reg into b
	ld c, a		; Load low byte of reg into c
	ld a, [hli]	; Load value to put into reg
	ld [bc], a	; Load value into reg
	jr .play_sfx_next_register

; If the register is rAUD4POLY, calculate the note's polynomial counter thanks to hUGEDriver's function
.play_sfx_polynomial_counter:
	ld d, a				; Save rAUD4POLY_lowb
	ld a, [hli]			; Load hUGETracker note
	; push hl
	call get_note_poly
	; pop hl
	ld b, $FF			; Load high byte of reg into b
	ld c, d				; Load low byte of reg into c
	ld [bc], a			; Load value into reg
	jr .play_sfx_next_register

.play_sfx_done:
	ret
