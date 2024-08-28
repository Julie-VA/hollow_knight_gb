SECTION "Text", ROM0

text_font_tile_data: INCBIN "resources/area51_font.2bpp"
text_font_tile_data_end:

load_text_font_into_vram:
	; Copy the tile data
	ld de, text_font_tile_data ; de contains the address where data will be copied from;
	ld hl, $9000 ; hl contains the address where data will be copied to;
	ld bc, text_font_tile_data_end - text_font_tile_data ; bc contains how many bytes we have to copy.
    jp copy_de_into_memory_at_hl