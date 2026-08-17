package main

import rl "raylib"
import "core:math"

circle_overlay_texture: rl.Texture2D

load_gui :: proc() {
	circle_overlay_texture = rl.LoadTexture("texture/circle_overlay.png")
}

unload_gui :: proc() {
	rl.UnloadTexture(circle_overlay_texture)
}

draw_health_bar :: proc() {
	BUFFER :: f32(5)
	SHELL_BUFFER :: f32(3)
	bar_size := rl.Vector2{256, 48}
		
	shell_pos := rl.Vector2{-BUFFER, SCREEN_SIZE.y - bar_size.y - BUFFER}
	shell_rec := rl.Rectangle{shell_pos.x, shell_pos.y, bar_size.x + BUFFER * 2, bar_size.y + BUFFER * 2}
	rl.DrawRectangleRounded(shell_rec, 0.3, 10, rl.BLACK)
	
	health_bar_size := bar_size + 5
	health_bar_size.x = health_bar_size.x * player.health / get_max_health(len(player.hexagon_types))
	health_bar_rec := rl.Rectangle{shell_pos.x, shell_pos.y + 5, health_bar_size.x, health_bar_size.y}
	rl.DrawRectangleRounded(health_bar_rec, 0.3, 10, rl.RED)
	
	sprint_bar_size := bar_size + 5
	sprint_bar_size.x = sprint_bar_size.x * player.sprint_secs / MAX_SPRINT_SECS
	sprint_bar_rec := rl.Rectangle{shell_pos.x, shell_pos.y + 45, sprint_bar_size.x, sprint_bar_size.y}
	rl.DrawRectangleRec(sprint_bar_rec, rl.SKYBLUE)
}

draw_spell_menu :: proc() {
	if !player.spell_mode do return

	src: rl.Rectangle
	switch player.active_spell.? {
	case .HEALTH_PAD: src = get_hexagon_texture_src(.HEALTH_PAD)
	case .ICE_BALL: src = get_hexagon_texture_src(.ICE_BALL)
	case .FIREBALL: src = get_hexagon_texture_src(.FIREBALL)
	case .BLACK_HOLE: src = get_hexagon_texture_src(.BLACK_HOLE)
	}

	cooldown := int(math.ceil(player.spell_cooldowns[player.active_spell.?]))
	cooldown_text := rl.TextFormat("%d", cooldown)
	BOX_SIZE :: f32(96)
	BUFFER :: f32(15)

	dest := rl.Rectangle{SCREEN_SIZE.x - BOX_SIZE / 2 - BUFFER, BUFFER + BOX_SIZE / 2, BOX_SIZE, BOX_SIZE}
	rot := math.mod_f32(f32(rl.GetTime()), 360) * 15
	
	rl.DrawTexturePro(hexagon_sheet, src, dest, BOX_SIZE / 2, rot, rl.WHITE if cooldown <= 0 else rl.GRAY)
	if cooldown > 0 do draw_text_center(cooldown_text, {SCREEN_SIZE.x - (BUFFER + BOX_SIZE / 2), BUFFER + BOX_SIZE / 2}, 32, .QUICKSAND_MEDIUM)
}

draw_active_spell_preview :: proc() {
	if !player.spell_mode do return
	hexagon_type_amounts := get_hexagon_type_amounts(player.clump)
	if player.spell_cooldowns[player.active_spell.?] > 0 do return // If the active spell is on cooldown, don't draw the preview
	switch player.active_spell.? {
	case .HEALTH_PAD: {
		_, size, _ := get_health_pad_stats(hexagon_type_amounts)
		size *= player.camera.zoom
		pos := world_to_camera(player.pos)
		rec := rl.Rectangle{pos.x - size / 2, pos.y - size / 2, size, size}
		rl.DrawRectangleRoundedLinesEx(rec, 0.2, 10, 7, rl.GREEN)
	}
	case .ICE_BALL: {
		src := rl.Rectangle{0, 0, f32(circle_overlay_texture.width), f32(circle_overlay_texture.height)}
		size := ICE_BALL_SIZE * player.camera.zoom
		dest := rl.Rectangle{rl.GetMousePosition().x, rl.GetMousePosition().y, size, size}
		rot := math.mod_f32(f32(rl.GetTime()), 360) * 50
		rl.DrawTexturePro(circle_overlay_texture, src, dest, size / 2, rot, rl.SKYBLUE)
	}
	case .FIREBALL: {
		src := rl.Rectangle{0, 0, f32(circle_overlay_texture.width), f32(circle_overlay_texture.height)}
		_, size, _ := get_fireball_stats(hexagon_type_amounts)
		size *= player.camera.zoom
		dest := rl.Rectangle{rl.GetMousePosition().x, rl.GetMousePosition().y, size, size}
		rot := math.mod_f32(f32(rl.GetTime()), 360) * 50
		rl.DrawTexturePro(circle_overlay_texture, src, dest, size / 2, rot, rl.ORANGE)
	}
	case .BLACK_HOLE: {
		src := rl.Rectangle{0, 0, f32(circle_overlay_texture.width), f32(circle_overlay_texture.height)}
		_, _, size := get_black_hole_stats(hexagon_type_amounts)
		size *= player.camera.zoom
		dest := rl.Rectangle{rl.GetMousePosition().x, rl.GetMousePosition().y, size, size}
		rot := math.mod_f32(f32(rl.GetTime()), 360) * 50
		rl.DrawTexturePro(circle_overlay_texture, src, dest, size / 2, rot, rl.PURPLE)
	}
	}
}

draw_bound_powerups :: proc(bound_powerups: [Powerup_Type]Bound_Powerup) {
	SIZE :: 64
	BUFFER :: 20
	for powerup, type in bound_powerups {
		switch type {
		case .HEALTH: continue
		case .DAMAGE, .SPEED: {
			if powerup.time_remaining <= 0 do continue
			src := rl.Rectangle{f32(int(type)) * POWERUP_SRC_SIZE, 0, POWERUP_SRC_SIZE, POWERUP_SRC_SIZE}
			pos := SCREEN_SIZE - {(SIZE + BUFFER if type == .SPEED else 0) + SIZE / 2 + BUFFER, MAP_SIZE + SIZE / 2 + BUFFER}
			dest := rl.Rectangle{pos.x, pos.y, SIZE, SIZE}

			opacity := f32(255)
			if powerup.time_remaining < BOUND_POWERUP_TIME do opacity *= (powerup.time_remaining / f32(BOUND_POWERUP_TIME))
			color := rl.Color{255, 255, 255, u8(opacity)}
			
			rl.DrawTexturePro(powerup_sheet, src, dest, SIZE / 2, 0, color)
		}
		}
	}
}