INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "libs/input.asm"

SECTION "InputUtilsVariables", WRAM0

m_wait_key:: db

SECTION "InputUtils", ROM0

wait_for_key_function:
    ; Save our original value
    push bc

	
wait_for_key_function_loop:
	; save the keys last frame
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
    jp z, wait_for_key_function_not_pressed
    
	ld a, [w_last_keys]
    and b
    jp nz, wait_for_key_function_not_pressed

	; restore our original value
	pop bc

    ret

wait_for_key_function_not_pressed:
    ; Wait a small amount of time
    ; Save our count in this variable
    ld a, 1
    ld [w_vblank_count], a

    ; Call our function that performs the code
    call wait_vblank

    jp wait_for_key_function_loop