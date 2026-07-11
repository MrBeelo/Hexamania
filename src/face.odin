package main

import rl "vendor:raylib"

face, cores: rl.Texture2D

LoadFace :: proc() {
	face = rl.LoadTexture("res/face.png")
	cores = rl.LoadTexture("res/cores.png")
}

UnloadFace :: proc() {
	rl.UnloadTexture(face)
	rl.UnloadTexture(cores)
}

DrawFace :: proc(pos: rl.Vector2, vel: rl.Vector2, level: int) {
	size := GetFaceSize(level)
	face_src := rl.Rectangle{0, 0, f32(face.width), f32(face.height)}
	face_dest := rl.Rectangle{pos.x, pos.y, size, size}
	rl.DrawTexturePro(face, face_src, face_dest, size / 2, 0, rl.WHITE)

	core_src := rl.Rectangle{0, 0, f32(cores.width), f32(cores.height)}
	core_dest := rl.Rectangle{pos.x, pos.y, size, size}
	core_dest.x += vel.x; core_dest.y += vel.y
	rl.DrawTexturePro(cores, core_src, core_dest, size / 2, 0, rl.WHITE)
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

DrawPlayerFace :: proc() {
	vel := VelocityFrom2Points(CameraPos(player), rl.GetMousePosition())
	DrawFace(player.pos, vel, GetPlayerLevel(player))
}

DrawEnemyFace :: proc(enemy: Enemy) {
	DrawFace(enemy.pos, rl.Vector2Normalize(enemy.vel), GetLevel(enemy.hexagon_types))
}