INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "EnemiesVariables", WRAM0

w_enemy_2_active::		db
w_enemy_2_position_x::	db
w_enemy_2_position_y::	db
w_enemy_2_type::		db
w_enemy_2_health::		db

w_enemy_2_accu::		db

; Method using a certain amount of continuous bytes for all enemies. w_current_enemy allows us to easily store the position of the current enemy in these blocks of bytes.
; w_enemies:: ds MAX_ENEMY_COUNT*PER_ENEMY_BYTES_COUNT
; w_current_enemy::	dw

; Other method but I don't see the point of this compared to the clarity of the separate variables right now. Useful for initializing since it's contiguous memory.
; w_enemy_1:: db 1, 136, 144, CRAWLID_HEALTH, CRAWLID
; w_enemy_2:: db 1, 16, 16, VENGEFLY_HEALTH, VENGEFLY


SECTION "Enemies", ROM0

enemies_tile_data: INCBIN "resources/sprites_enemies.2bpp"
enemies_tile_data_end:


initialize_enemies::
	; Copy the enemies' tile data into VRAM
    ld de, enemies_tile_data
    ld hl, ENEMIES_TILES_START
    ld bc, enemies_tile_data_end - enemies_tile_data
    call copy_de_into_memory_at_hl

	call initialize_crawlid
	call initialize_vengefly	

	ret


update_enemies::
	ld a, [w_crawlid_active]
	or a
	call nz, update_crawlid

	ld a, [w_vengefly_active]
	or a
	call nz, update_vengefly

	ret
