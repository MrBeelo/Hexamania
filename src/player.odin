package main

import rl "vendor:raylib"

Player :: struct {
	using clump: HexagonClump,
	camera: rl.Camera2D,
}

NewPlayer :: proc() -> Player {
	camera := rl.Camera2D{screen_size / 2, 0, 0, 1}
	return Player{ NewHexagonClump({.BLANK}, 0), camera }
}

UpdatePlayer :: proc(plr: ^Player) {
	// Movement
	if Holding(.UP) {
	 	Accelerate(&plr.vel.y, -SPEED)
	} else if Holding(.DOWN) {
		Accelerate(&plr.vel.y, SPEED)
	} else do Accelerate(&plr.vel.y, 0)
	
	if Holding(.LEFT) {
	 	Accelerate(&plr.vel.x, -SPEED)
	} else if Holding(.RIGHT) {
	 	Accelerate(&plr.vel.x, SPEED)
	} else do Accelerate(&plr.vel.x, 0)

	// Camera Management
	HandlePlayerCamera(plr)

	// Hexagon Updating (must always do this)
	UpdateHexagonClump(&plr.clump)
}

DrawPlayer :: proc(plr: ^Player) {
	// Hexagon Drawing (must always do this)
	DrawHexagonClump(plr.clump)
}

Accelerate :: proc(vel: ^f32, speed: f32, acceleration := ACCELERATION) {
	if vel^ > speed do vel^ -= f32(acceleration) * rl.GetFrameTime()
	if vel^ < speed do vel^ += f32(acceleration) * rl.GetFrameTime()
}

HandlePlayerCamera :: proc(plr: ^Player) {	
	for i in 0..=1 {
		diff := plr.pos[i] - plr.camera.target[i]
		threshold := screen_size[i] / 5

		if diff > threshold do plr.camera.target[i] = plr.pos[i] - threshold
		if diff < -threshold do plr.camera.target[i] = plr.pos[i] + threshold
	}
}