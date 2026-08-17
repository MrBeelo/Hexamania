package main

import rl "raylib"

MAP_SIZE :: f32(128)

draw_map :: proc() {
	if player.camera.zoom == 0 do return

	map_zoom :: 0.5
	sim_scr_size := (SCREEN_SIZE / player.camera.zoom) / map_zoom
	map_center := SCREEN_SIZE - MAP_SIZE / 2
	screen_to_map_ratio := MAP_SIZE / sim_scr_size.x

	// Draw map background
	BUFFER :: 20
	map_rec := rl.Rectangle{map_center.x - MAP_SIZE / 2, map_center.y - MAP_SIZE / 2, MAP_SIZE + BUFFER, MAP_SIZE + BUFFER}

	BORDER_THICK :: 7
	border_rec := rl.Rectangle{map_rec.x - BORDER_THICK, map_rec.y - BORDER_THICK, map_rec.width + BORDER_THICK + BUFFER, 
		map_rec.height + BORDER_THICK + BUFFER}
	
	rl.DrawRectangleRounded(border_rec, 0.3, 10, rl.BLACK)
	rl.DrawRectangleRounded(map_rec, 0.3, 10, rl.LIGHTGRAY)

	// Draw screen border 
	screen_border_rec := rl.Rectangle{map_center.x - MAP_SIZE / 2 * map_zoom, map_center.y - MAP_SIZE / 2 * map_zoom, 
		MAP_SIZE * map_zoom, MAP_SIZE * map_zoom}
	rl.DrawRectangleLinesEx(screen_border_rec, 2, rl.BLUE)

	// Draw clumps (entities)
	for clump in hexagon_clumps[:clump_cap] {
		color := rl.BLUE if clump.uuid == player.uuid else rl.RED
		draw_point_in_map(clump.pos, color, screen_to_map_ratio, map_rec)
	}

	// Draw collectibles
	for heart in hearts do draw_point_in_map(heart.center, rl.PINK, screen_to_map_ratio, map_rec)
	for powerup in world_powerups do draw_point_in_map(powerup.pos, rl.GREEN, screen_to_map_ratio, map_rec)
}

draw_point_in_map :: proc(pos: rl.Vector2, color: rl.Color, ratio: f32, map_rec: rl.Rectangle) {
	map_pos := world_to_map(pos, ratio, {map_rec.x + MAP_SIZE / 2, map_rec.y + MAP_SIZE / 2})
	if !rl.CheckCollisionPointRec(map_pos, map_rec) do return
	rl.DrawCircleV(map_pos, 2, color)
}

world_to_map :: proc(pos: rl.Vector2, ratio: f32, map_center: rl.Vector2) -> rl.Vector2 {
	relative_pos := pos - player.camera.target
	return map_center + relative_pos * ratio
}