package main

import rl "vendor:raylib"
import "core:math"

PLAYER_SPEED :: 3 * 60
PLAYER_ACCELERATION :: 5 * 60

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
	 	Accelerate(&plr.vel.y, -PLAYER_SPEED)
	} else if Holding(.DOWN) {
		Accelerate(&plr.vel.y, PLAYER_SPEED)
	} else do Accelerate(&plr.vel.y, 0)
	
	if Holding(.LEFT) {
	 	Accelerate(&plr.vel.x, -PLAYER_SPEED)
	} else if Holding(.RIGHT) {
	 	Accelerate(&plr.vel.x, PLAYER_SPEED)
	} else do Accelerate(&plr.vel.x, 0)

	// Clamp velocities down to 0 if they are low and player isn't moving
	if !Holding(.HORIZ) && !Holding(.VERT) {
		DEADZONE :: f32(3)
		if math.abs(plr.vel.x) < DEADZONE do plr.vel.x = 0
		if math.abs(plr.vel.y) < DEADZONE do plr.vel.y = 0
	}

	plr.spr.sprinting = Holding(.SPRINT) && plr.spr.sprint_secs > 0

	// Camera Management
	HandlePlayerCamera(plr)

	UpdateHexagonClump(&plr.clump)
}

DrawPlayer :: proc(plr: ^Player) {
	DrawHexagonClump(plr.clump)
	DrawDebugText(plr.pos, "%.0f hp, %d%d%d%d", plr.health, plr.uuid[8], plr.uuid[9], plr.uuid[10], plr.uuid[11])
}

Accelerate :: proc(vel: ^f32, speed: f32, acceleration := PLAYER_ACCELERATION) {
	if vel^ > speed do vel^ -= f32(acceleration) * rl.GetFrameTime()
	if vel^ < speed do vel^ += f32(acceleration) * rl.GetFrameTime()
}

HandlePlayerCamera :: proc(plr: ^Player) {	
	for i in 0..=1 {
		diff := plr.pos[i] - plr.camera.target[i]
		threshold := screen_size[i] / 5 / plr.camera.zoom

		if diff > threshold do plr.camera.target[i] = plr.pos[i] - threshold
		if diff < -threshold do plr.camera.target[i] = plr.pos[i] + threshold
	}

	plr.camera.zoom = GetCameraZoom(GetPlayerLevel(plr^))
}

CameraPos :: proc(plr: Player) -> rl.Vector2 {
	return plr.pos - plr.camera.target + plr.camera.offset
}

GetCameraZoom :: proc(level: int) -> f32 {
	switch level {
	case 1: return 1.2
	case 2: return 1.1
	case 3: return 0.9
	case 4: return 0.7
	}

	return 1
}

GetPlayerLevel :: proc(plr: Player) -> int {
	hexagons := len(plr.hexagon_types)
	switch {
	case hexagons < 1 + 6: return 1
	case hexagons < 1 + 6 + 12: return 2
	case hexagons < 1 + 6 + 12 + 18: return 3
	case hexagons == 1 + 6 + 12 + 18: return 4
	}

	return 1
}