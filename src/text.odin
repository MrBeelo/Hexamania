package main

import rl "vendor:raylib"

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
	case .QUICKSAND_LIGHT: return "res/font/Quicksand-Regular.ttf"
	case .QUICKSAND_MEDIUM: return "res/font/Quicksand-Medium.ttf"
	case .QUICKSAND_HEAVY: return "res/font/Quicksand-SemiBold.ttf"
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
	text_size := MeasureText(text, size, type, spacing)

	if border_info.bordered do for i in -1..=1 do for j in -1..=1 do if i != 0 || j != 0 {
		rl.DrawTextPro(font, text, center + {f32(i) * border_info.border_thickness, f32(j) * border_info.border_thickness}, 
			text_size / 2, 0, size, spacing, border_info.border_color)
	}
	
	rl.DrawTextPro(font, text, center, text_size / 2, 0, size, spacing, color)
}

MeasureText :: proc(text: cstring, size: f32, type := FontType.QUICKSAND_MEDIUM, spacing: f32 = 5) -> rl.Vector2 {
	return rl.MeasureTextEx(GetFont({type, size}), text, size, spacing)
}