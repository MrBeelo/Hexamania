package main

import rl "raylib"

Button :: struct {
	text: cstring,
	center: rl.Vector2, 
	function: proc(),
	size: f32,
	font_type: Font_Type,
	colors: [2]rl.Color, // Normal, Hover
	spacing: f32,
}

new_button :: proc(text: cstring, center: rl.Vector2, function: proc(), size: f32,
font_type := Font_Type.QUICKSAND_MEDIUM, colors: [2]rl.Color = rl.WHITE, spacing := f32(5)) -> Button {
	return Button{text, center, function, size, font_type, colors, spacing}
}

update_button :: proc(bt: ^Button) {
	text_size := measure_text(bt.text, bt.size, bt.font_type, bt.spacing)
	top_left_pos := bt.center - (text_size / 2)
	button_rec := rl.Rectangle{top_left_pos.x, top_left_pos.y, text_size.x, text_size.y}
	hovered := rl.CheckCollisionPointRec(rl.GetMousePosition(), button_rec)
	if hovered && rl.IsMouseButtonPressed(.LEFT) { bt.function(); play_sound(ui_confirm) }
}

draw_button :: proc(bt: Button) {
	text_size := measure_text(bt.text, bt.size, bt.font_type, bt.spacing)
	top_left_pos := bt.center - (text_size / 2)
	button_rec := rl.Rectangle{top_left_pos.x, top_left_pos.y, text_size.x, text_size.y}
	hovered := rl.CheckCollisionPointRec(rl.GetMousePosition(), button_rec)
	color := bt.colors[0] if !hovered else bt.colors[1]
	
	draw_text_center(bt.text, bt.center, bt.size, bt.font_type, color, {}, bt.spacing)
}