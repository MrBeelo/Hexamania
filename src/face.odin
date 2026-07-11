package main

import rl "vendor:raylib"

faces: [FaceExpression]rl.Texture2D
cores: rl.Texture2D

FaceExpression :: enum {
	NORMAL,
	CARET,
	DEAD,
}

LoadFace :: proc() {
	faces = {
		.NORMAL = rl.LoadTexture("res/face/normal_face.png"),
		.CARET = rl.LoadTexture("res/face/caret_face.png"),
		.DEAD = rl.LoadTexture("res/face/dead_face.png"),
	}
	
	cores = rl.LoadTexture("res/face/cores.png")
}

UnloadFace :: proc() {
	for face in faces do rl.UnloadTexture(face)
	rl.UnloadTexture(cores)
}

DrawFace :: proc(pos: rl.Vector2, vel: rl.Vector2, level: int, expression: FaceExpression, opacity: u8) {
	color := rl.Color{255, 255, 255, opacity}
	
	texture := faces[expression]
	size := GetFaceSize(level)
	face_src := rl.Rectangle{0, 0, f32(texture.width), f32(texture.height)}
	face_dest := rl.Rectangle{pos.x, pos.y, size, size}
	rl.DrawTexturePro(texture, face_src, face_dest, size / 2, 0, color)

	if expression == .NORMAL {
		core_src := rl.Rectangle{0, 0, f32(cores.width), f32(cores.height)}
		core_dest := rl.Rectangle{pos.x, pos.y, size, size}
		core_dest.x += vel.x; core_dest.y += vel.y
		rl.DrawTexturePro(cores, core_src, core_dest, size / 2, 0, color)
	}
}

GetFaceSize :: proc(level: int) -> f32 {
	switch level {
	case 1: return 32
	case 2: return 48
	case 3: return 64
	case 4: return 80
	}

	return 32
}

GetFaceExpression :: proc(clump: HexagonClump) -> FaceExpression {
	if clump.dead_time > 0 do return .DEAD
	if clump.kill_happiness_time > 0 do return .CARET
	return .NORMAL
}

DrawPlayerFace :: proc() {
	vel := VelocityFrom2Points(CameraPos(player), rl.GetMousePosition())
	opacity := u8(255 * (1 - player.dead_time * 2)) if player.dead_time > 0 else 255
	DrawFace(player.pos, vel, GetPlayerLevel(player), GetFaceExpression(player.clump), opacity)
}

DrawEnemyFace :: proc(enemy: Enemy) {
	opacity := u8(255 * (1 - enemy.dead_time * 2)) if enemy.dead_time > 0 else 255
	DrawFace(enemy.pos, rl.Vector2Normalize(enemy.vel), GetLevel(enemy.hexagon_types), GetFaceExpression(enemy.clump), opacity)
}