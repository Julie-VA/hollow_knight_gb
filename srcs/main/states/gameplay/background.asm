INCLUDE "srcs/main/utils/hardware.inc"
INCLUDE "srcs/main/utils/constants.inc"

SECTION "Background", ROM0

bg_test_tile_data: INCBIN "resources/bg_test.2bpp"
bg_test_tile_data_end:
 
bg_test_tile_map: INCBIN "resources/bg_test.tilemap"
bg_test_tile_map_end:

initialize_background::
	; Copy the background tile data into VRAM
	ld de, bg_test_tile_data ; de contains the address where data will be copied from;
	ld hl, $9000 ; hl contains the address where data will be copied to;
	ld bc, bg_test_tile_data_end - bg_test_tile_data ; bc contains how many bytes we have to copy.
    call copy_de_into_memory_at_hl

	; Copy the tilemap
	ld de, bg_test_tile_map
	ld hl, $9800
	ld bc, bg_test_tile_map_end - bg_test_tile_map
    call copy_de_into_memory_at_hl

	ret