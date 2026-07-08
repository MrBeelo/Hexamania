package main

import rl "vendor:raylib"

DrawDebugText :: proc(pos: rl.Vector2, txt: cstring, args: ..any) {
	text := rl.TextFormat(txt, ..args)
	text_size := f32(rl.MeasureText(text, 16))
	text_pos := pos - {text_size / 2, 50}
	rl.DrawTextEx(rl.GetFontDefault(), text, text_pos, 16, 2, rl.RED)
}