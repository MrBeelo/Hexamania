package main

import rl "vendor:raylib"
import "core:math/rand"

HandlePlayerCamera :: proc(plr: ^Player) {	
	for i in 0..=1 {
		diff := plr.pos[i] - plr.camera.target[i]
		threshold := SCREEN_SIZE[i] / 10 / plr.camera.zoom

		if diff > threshold do plr.camera.target[i] = plr.pos[i] - threshold
		if diff < -threshold do plr.camera.target[i] = plr.pos[i] + threshold
	}

	target_zoom := GetCameraZoom(GetLevel(plr.hexagon_types))
	if plr.camera.zoom < target_zoom do plr.camera.zoom += rl.GetFrameTime()
	if plr.camera.zoom > target_zoom do plr.camera.zoom -= rl.GetFrameTime()
}

WorldToCamera :: proc(pos: rl.Vector2, camera := player.camera) -> rl.Vector2 {
	return (pos - camera.target) * camera.zoom + camera.offset
}

GetCameraZoom :: proc(level: int) -> f32 {
	switch level {
	case 1: return 1.1
	case 2: return 0.9
	case 3: return 0.8
	case 4: return 0.7
	}

	return 1
}

// For spawning enemies and powerups
GetRandomSpawnPos :: proc(range: f32 = 120) -> rl.Vector2 {
	visible_screen_size := SCREEN_SIZE / player.camera.zoom
	min_dist := visible_screen_size / 2
	max_dist := min_dist + range

	pos_x, pos_y: f32
	x_free := bool(rand.int_range(0, 2))
	if x_free {
		pos_x = rand.float32_range(-max_dist.x, max_dist.x)
		pos_y = RangeRand({min_dist.y, max_dist.y})
	} else {
		pos_x = RangeRand({min_dist.x, max_dist.x})
		pos_y = rand.float32_range(-max_dist.y, max_dist.y)
	}
	
	pos := player.camera.target + {pos_x, pos_y}
	return pos
}

GetWorldCameraRect :: proc(cam := player.camera) -> rl.Rectangle {
	size := SCREEN_SIZE * cam.zoom
	pos := cam.target - size / 2
	return {pos.x, pos.y, size.x, size.y}
}