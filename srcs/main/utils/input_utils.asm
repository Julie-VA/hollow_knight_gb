INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "InputUtilsVariables", WRAM0

m_wait_key:: db

SECTION "InputUtils", ROM0

wait_for_key_title::	
wait_for_key_title_loop:
	; Play OST
	call hUGE_dosound

	; Save the keys last frame
	ld a, [w_cur_keys]
	ld [w_last_keys], a
    
	; This is in input.asm
	; It's straight from: https://gbdev.io/gb-asm-tutorial/part2/input.html
	; In their words (paraphrased): reading player input for gameboy is NOT a trivial task
	; So it's best to use some tested code
    call input

	ld a, [m_wait_key]
    ld b, a
	ld a, [w_cur_keys]
    and b
    jp z, wait_for_key_title_not_pressed

	ld a, [w_last_keys]
    and b
    jp nz, wait_for_key_title_not_pressed

    ret

wait_for_key_title_not_pressed:
	halt
    jp wait_for_key_title_loop