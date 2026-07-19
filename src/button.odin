package main

import rl "vendor:raylib"

Button :: struct {
	text: cstring,
	center: rl.Vector2, 
	function: proc(),
	size: f32,
	font_type: FontType,
	colors: [2]rl.Color, // Normal, Hover
	spacing: f32,
}

NewButton :: proc(text: cstring, center: rl.Vector2, function: proc(), size: f32,
font_type := FontType.QUICKSAND_MEDIUM, colors: [2]rl.Color = rl.WHITE, spacing := f32(5)) -> Button {
	return Button{text, center, function, size, font_type, colors, spacing}
}

UpdateButton :: proc(bt: ^Button) {
	text_size := MeasureText(bt.text, bt.size, bt.font_type, bt.spacing)
	top_left_pos := bt.center - (text_size / 2)
	button_rect := rl.Rectangle{top_left_pos.x, top_left_pos.y, text_size.x, text_size.y}
	hovered := rl.CheckCollisionPointRec(rl.GetMousePosition(), button_rect)
	if hovered && rl.IsMouseButtonPressed(.LEFT) { bt.function(); rl.PlaySound(ui_confirm) }
}

DrawButton :: proc(bt: Button) {
	text_size := MeasureText(bt.text, bt.size, bt.font_type, bt.spacing)
	top_left_pos := bt.center - (text_size / 2)
	button_rect := rl.Rectangle{top_left_pos.x, top_left_pos.y, text_size.x, text_size.y}
	hovered := rl.CheckCollisionPointRec(rl.GetMousePosition(), button_rect)
	color := bt.colors[0] if !hovered else bt.colors[1]
	
	DrawTextCenter(bt.text, bt.center, bt.size, bt.font_type, color, {}, bt.spacing)
}