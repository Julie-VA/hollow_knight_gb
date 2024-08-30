INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "PlayerVariables", WRAM0

; First byte is low, second is high (little endian)
w_player_position_x:: dw
w_player_position_y:: dw

SECTION "Player", ROM0

knight_tile_data: INCBIN "resources/knight_sprites.2bpp"
knight_tile_data_end:

initialize_player::
    ; Place in the middle of the screen
    xor a
    ld [w_player_position_x], a
    ld [w_player_position_y], a

    ld a, 5
    ld [w_player_position_x + 1], a
    ld [w_player_position_y + 1], a

copy_player_tile_data_into_vram:
    ; Copy the player's tile data into VRAM
    ld de, knight_tile_data
    ld hl, PLAYER_TILES_START
    ld bc, knight_tile_data_end - knight_tile_data
    call copy_de_into_memory_at_hl
	ret

update_player::

update_player_handle_input:
    ld a, [w_cur_keys]
    and PADF_LEFT
    call nz, move_left

    ld a, [w_cur_keys]
    and PADF_RIGHT
    call nz, move_right

move_left:
    ; Decrease the player's x position
    ld a, [w_player_position_x] ; Load lower byte
    sub PLAYER_MOVE_SPEED
    ld [w_player_position_x], a

    ld a, [w_player_position_x + 1] ; Load upper byte
    sbc 0 ; Substract carry flag to upper byte if lower byte substraction underflowed (ensures correct substraction)
    ld [w_player_position_x + 1], a
    ret

move_right:
    ; Increase the player's x position
    ld a, [w_player_position_x] ; Load lower byte
    add PLAYER_MOVE_SPEED
    ld [w_player_position_x], a

    ld a, [w_player_position_x + 1] ; Load upper byte
    adc 0 ; Add carry flag to upper byte if lower byte addition overflowed (ensures correct incrementation)
    ld [w_player_position_x + 1], a
    ret