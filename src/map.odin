package main

import rl "vendor:raylib"

MAP_SIZE :: f32(128)

DrawMap :: proc() {
	if player.camera.zoom == 0 do return

	map_zoom :: 0.5
	sim_scr_size := (screen_size / player.camera.zoom) / map_zoom
	map_center := screen_size - MAP_SIZE / 2
	screen_to_map_ratio := MAP_SIZE / sim_scr_size.x

	// Draw map background
	// NOTE: Should probably change
	map_rect := rl.Rectangle{map_center.x - MAP_SIZE / 2, map_center.y - MAP_SIZE / 2, MAP_SIZE, MAP_SIZE}
	rl.DrawRectangleRec(map_rect, rl.WHITE)

	// Draw screen border 
	screen_border_rect := rl.Rectangle{map_center.x - MAP_SIZE / 2 * map_zoom, map_center.y - MAP_SIZE / 2 * map_zoom, 
		MAP_SIZE * map_zoom, MAP_SIZE * map_zoom}
	rl.DrawRectangleLinesEx(screen_border_rect, 2, rl.BLUE)

	// Draw clumps (entities)
	for clump in GetAllClumps() {
		color := rl.BLUE if clump.uuid == player.uuid else rl.RED
		DrawInMap(clump.pos, color, screen_to_map_ratio, map_rect)
	}

	// Draw collectibles
	for heart in hearts do DrawInMap(heart.center, rl.PINK, screen_to_map_ratio, map_rect)
	for powerup in world_powerups do DrawInMap(powerup.pos, rl.GREEN, screen_to_map_ratio, map_rect)
}


DrawInMap :: proc(pos: rl.Vector2, color: rl.Color, ratio: f32, map_rect: rl.Rectangle) {
	map_pos := WorldToMap(pos, ratio, {map_rect.x + MAP_SIZE / 2, map_rect.y + MAP_SIZE / 2})
	if !rl.CheckCollisionPointRec(map_pos, map_rect) do return
	rl.DrawCircleV(map_pos, 2, color)
}

WorldToMap :: proc(pos: rl.Vector2, ratio: f32, map_center: rl.Vector2) -> rl.Vector2 {
	relative_pos := pos - player.camera.target
	return map_center + relative_pos * ratio
}