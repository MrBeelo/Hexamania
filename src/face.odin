package main

import rl "raylib"

face_sheet: rl.Texture2D
cores: rl.Texture2D

Face_Expression :: enum {
	NORMAL,
	CARET,
	DEAD,
}

load_face :: proc() {
	face_sheet = rl.LoadTexture("texture/face_sheet.png")
	cores = rl.LoadTexture("texture/face_cores.png")
}

unload_face :: proc() {
	rl.UnloadTexture(face_sheet)
	rl.UnloadTexture(cores)
}

draw_face :: proc(pos: rl.Vector2, vel: rl.Vector2, level: int, expression: Face_Expression, opacity: u8) {
	color := rl.Color{255, 255, 255, opacity}

	FACE_SRC_SIZE :: 256
	size := get_face_size(level)
	face_src := rl.Rectangle{f32(int(expression)) * FACE_SRC_SIZE, 0, FACE_SRC_SIZE, FACE_SRC_SIZE}
	face_dest := rl.Rectangle{pos.x, pos.y, size, size}
	rl.DrawTexturePro(face_sheet, face_src, face_dest, size / 2, 0, color)

	if expression == .NORMAL {
		core_src := rl.Rectangle{0, 0, f32(cores.width), f32(cores.height)}
		core_dest := rl.Rectangle{pos.x, pos.y, size, size}
		core_dest.x += vel.x; core_dest.y += vel.y
		rl.DrawTexturePro(cores, core_src, core_dest, size / 2, 0, color)
	}
}

get_face_size :: proc(level: int) -> f32 {
	switch level {
	case 1: return 32
	case 2: return 48
	case 3: return 64
	case 4: return 80
	}

	return 32
}

get_face_expression :: proc(clump: Hexagon_Clump) -> Face_Expression {
	if clump.dead_time > 0 do return .DEAD
	if clump.kill_happiness_time > 0 do return .CARET
	return .NORMAL
}

draw_player_face :: proc() {
	vel := velocity_from_points(world_to_camera(player.pos), rl.GetMousePosition())
	opacity := u8(255 * (1 - player.dead_time * 2)) if player.dead_time > 0 else 255
	draw_face(player.pos, vel, get_level(player.hexagon_types), get_face_expression(player.clump), opacity)
}

draw_enemy_face :: proc(enemy: Enemy) {
	opacity := u8(255 * (1 - enemy.dead_time * 2)) if enemy.dead_time > 0 else 255
	draw_face(enemy.pos, rl.Vector2Normalize(enemy.vel), get_level(enemy.hexagon_types), get_face_expression(enemy.clump), opacity)
}