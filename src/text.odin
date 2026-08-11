package main

import rl "raylib"
import "raylib/rlgl"
import "core:unicode/utf8"
import "core:strconv"

FontInfo :: struct { type: FontType, size: f32 }
font_cache: map[FontInfo]rl.Font
FontType :: enum {
	QUICKSAND_LIGHT,
	QUICKSAND_MEDIUM,
	QUICKSAND_HEAVY,
}

BorderInfo :: struct { bordered: bool, border_thickness: f32, border_color: rl.Color, }

LoadFonts :: proc() {
	font_cache = make(map[FontInfo]rl.Font)
}

UnloadFonts :: proc() {
	for _, font in font_cache do rl.UnloadFont(font)
}

GetFontPath :: proc(type: FontType) -> cstring {
	switch type {
	case .QUICKSAND_LIGHT: return "font/Quicksand-Regular.ttf"
	case .QUICKSAND_MEDIUM: return "font/Quicksand-Medium.ttf"
	case .QUICKSAND_HEAVY: return "font/Quicksand-SemiBold.ttf"
	}

	return ""
}

GetFont :: proc(info: FontInfo) -> rl.Font {
	if font, ok := font_cache[info]; ok do return font; else {
		new_font := rl.LoadFontEx(GetFontPath(info.type), i32(info.size), nil, 0)
		rl.SetTextureFilter(new_font.texture, .BILINEAR)
		font_cache[info] = new_font
		return new_font
	}
	
	return rl.GetFontDefault()
}

DrawDebugText :: proc(pos: rl.Vector2, txt: cstring, args: ..any) {
	text := rl.TextFormat(txt, ..args)
	text_size := f32(rl.MeasureText(text, 16))
	text_pos := pos - {text_size / 2, 50}
	rl.DrawTextEx(rl.GetFontDefault(), text, text_pos, 16, 2, rl.RED)
}

DrawText :: proc(text: cstring, pos: rl.Vector2, size: f32, type := FontType.QUICKSAND_MEDIUM, color := rl.WHITE, border_info := BorderInfo{}, spacing: f32 = 5) {
	if text == "" do return
	font := GetFont({type, size})

	if border_info.bordered do for i in -1..=1 do for j in -1..=1 do if i != 0 || j != 0 {
		rl.DrawTextPro(font, text, pos + {f32(i) * border_info.border_thickness, f32(j) * border_info.border_thickness}, 
			0, 0, size, spacing, border_info.border_color)
	}
	
	rl.DrawTextPro(font, text, pos, 0, 0, size, spacing, color)
}

DrawTextCenter :: proc(text: cstring, center: rl.Vector2, size: f32, type := FontType.QUICKSAND_MEDIUM, color := rl.WHITE, border_info := BorderInfo{}, spacing: f32 = 5) {
	if text == "" do return
	font := GetFont({type, size})
	text_size := MeasureTextProStyled(text, size, type, spacing)

	if border_info.bordered do for i in -1..=1 do for j in -1..=1 do if i != 0 || j != 0 {
		DrawTextProStyled(font, string(text), center + {f32(i) * border_info.border_thickness, f32(j) * border_info.border_thickness}, 
			text_size / 2, 0, size, spacing, border_info.border_color)
	}
	
	DrawTextProStyled(font, string(text), center, text_size / 2, 0, size, spacing, color)
}

MeasureText :: proc(text: cstring, size: f32, type := FontType.QUICKSAND_MEDIUM, spacing: f32 = 5) -> rl.Vector2 {
	return rl.MeasureTextEx(GetFont({type, size}), text, size, spacing)
}

DrawTextStyled :: proc(font: rl.Font, text: string, position: rl.Vector2, font_size: f32, spacing: f32, color: rl.Color) {
	text_len := len(text)

	col_front := color
	col_back := rl.BLANK
	back_rec_padding := 4

	text_offset_y, text_offset_x, text_line_spacing: f32
	scale_factor := font_size / f32(font.baseSize)

	for i := 0; i < text_len; {
		codepoint, codepoint_byte_count := utf8.decode_rune(text[i:])

		if codepoint == '\n' {
			text_offset_y += font_size + text_line_spacing
			text_offset_x = 0
		} else {
			if codepoint == '[' {
				if ((i + 2) < text_len) && (text[i + 1] == 'r') && (text[i + 2] == ']') {
                    col_front = color
                    col_back = rl.BLANK

                    i += 3
                    continue
                } else if (((i + 1) < text_len) && ((text[i + 1] == 'c') || (text[i + 1] == 'b'))) {
                	i += 2
                 	col_hex_text: [9]rune
                  	text_ptr := text[i:]

                   	col_hex_count := 0
                    for text_ptr[col_hex_count] != 0 && text_ptr[col_hex_count] != ']' {
                    	if IsValidStyleChar(text_ptr[col_hex_count]) {
                     		col_hex_text[col_hex_count] = rune(text_ptr[col_hex_count])
                       		col_hex_count += 1
                     	} else do break
                    }

                    col_hex_value, _ := strconv.parse_uint(utf8.runes_to_string(col_hex_text[:], context.temp_allocator), 16)
                    if text[i - 1] == 'c' {
                   		col_front = rl.GetColor(u32(col_hex_value))
                    } else if text[i - 1] == 'b' {
                   		col_back = rl.GetColor(u32(col_hex_value))
                    }

                    i += (col_hex_count + 1)
                    continue
                }
			}

			index := rl.GetGlyphIndex(font, codepoint)
			increase_x: f32

			if font.glyphs[index].advanceX == 0 {
				increase_x = font.recs[index].width * scale_factor + spacing
			} else {
				increase_x += f32(font.glyphs[index].advanceX) * scale_factor + spacing
			}

			if col_back.a > 0 do rl.DrawRectangleRec({position.x + text_offset_x, position.y + text_offset_y - f32(back_rec_padding),
				increase_x, font_size + 2 * f32(back_rec_padding)}, col_back)

			if codepoint != ' ' && codepoint != '\t' {
				rl.DrawTextCodepoint(font, codepoint, { position.x + text_offset_x, position.y + text_offset_y }, font_size, col_front)
			}

			text_offset_x += increase_x
		}

		i += codepoint_byte_count
	}
}

MeasureTextStyled :: proc(font: rl.Font, text: string, font_size: f32, spacing: f32) -> rl.Vector2 {
	text_size: rl.Vector2

	if len(text) <= 0 || text[0] == 0 do return text_size

	text_len := len(text)

	text_width: f32
	text_height := font_size
	scale_factor := font_size / f32(font.baseSize)

	index := 0
	valid_codepoint_counter := 0

	for i := 0; i < text_len; {
		codepoint, codepoint_byte_count := utf8.decode_rune(text[i:])

		if codepoint == '[' {
            if (i + 2) < text_len && text[i + 1] == 'r' && text[i + 2] == ']' {
                i += 3
                continue
            } else if (i + 1) < text_len && (text[i + 1] == 'c' || text[i + 1] == 'b') {
                i += 2

                text_ptr := text[i:]

                col_hex_count := 0
                for text_ptr[col_hex_count] != 0 && text_ptr[col_hex_count] != ']' {
                	if IsValidStyleChar(text_ptr[col_hex_count]) do col_hex_count += 1; else do break
                }

                i += (col_hex_count + 1)
                continue
            }
        } else if codepoint != '\n' {
            index = int(rl.GetGlyphIndex(font, codepoint))

            if font.glyphs[index].advanceX > 0 {
                text_width += f32(font.glyphs[index].advanceX)
            } else { 
                text_width += font.recs[index].width + f32(font.glyphs[index].offsetX)
            }

            valid_codepoint_counter += 1
            i += codepoint_byte_count
        }
	}

	text_size.x = text_width * scale_factor + (f32(valid_codepoint_counter) - 1) * spacing
    text_size.y = text_height

    return text_size
}

DrawTextProStyled :: proc(font: rl.Font, text: string, position: rl.Vector2, 
origin: rl.Vector2, rotation: f32, fontSize: f32, spacing: f32, tint: rl.Color) {
	rlgl.PushMatrix()
	
    rlgl.Translatef(position.x, position.y, 0)
    rlgl.Rotatef(rotation, 0, 0, 1)
    rlgl.Translatef(-origin.x, -origin.y, 0)
    DrawTextStyled(font, text, {}, fontSize, spacing, tint)

    rlgl.PopMatrix()
}

MeasureTextProStyled :: proc(text: cstring, size: f32, type := FontType.QUICKSAND_MEDIUM, spacing: f32 = 5) -> rl.Vector2 {
	return MeasureTextStyled(GetFont({type, size}), string(text), size, spacing)
}

@(private = "file")
IsValidStyleChar :: proc(char: u8) -> bool {
	return (char >= '0' && char <= '9') || 
		(char >= 'A' && char <= 'F') ||
        (char >= 'a' && char <= 'f')
}