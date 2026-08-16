package main

import rl "raylib"
import "core:math"
import "core:math/rand"

HEART_DECELERATION :: 5 * 60
hearts: [dynamic]Hexagon_Heart

Hexagon_Heart :: struct {
	using hexagon: Hexagon,
	vel: rl.Vector2,
	time_alive: f32,
}

throw_heart :: proc(pos: rl.Vector2, type: Hexagon_Type) {
	vel_x := union_range_rand({100, 150})
	vel_y := union_range_rand({100, 150})
	
	append(&hearts, Hexagon_Heart{{type, pos, 0, {}}, {vel_x, vel_y}, 0})
}

throw_random_heart :: proc(pos: rl.Vector2) {
	type := rand.choice_enum(Hexagon_Type)
	throw_heart(pos, type)
}

update_hearts :: proc() { for &heart, index in hearts do update_heart(&heart, index) }

update_heart :: proc(heart: ^Hexagon_Heart, index: int) {
	heart.time_alive += rl.GetFrameTime()
	heart.rot += rl.GetFrameTime() * (math.abs(heart.vel.x) + math.abs(heart.vel.y)) / 2
	
	heart.center += heart.vel * rl.GetFrameTime()
	accelerate(&heart.vel.x, 0, HEART_DECELERATION)
	accelerate(&heart.vel.y, 0, HEART_DECELERATION)

	DEADZONE :: f32(3)
	if math.abs(heart.vel.x) < DEADZONE do heart.vel.x = 0
	if math.abs(heart.vel.y) < DEADZONE do heart.vel.y = 0
	
	heart.hurtbox = get_hexagon_hurtbox(heart.center)

	lowest_dist := f32(9999)
	closest_box: rl.Rectangle
	for hexagon in player.clump.hexagons {
		dist := rl.Vector2Distance(heart.center, hexagon.center)
		if dist < lowest_dist {
			lowest_dist = dist
			closest_box = hexagon.hurtbox
		}
	}
	
	heart.vel = velocity_from_points(heart.center, player.pos) * (1 + heart.time_alive) * 30
	
	if rl.CheckCollisionRecs(closest_box, heart.hurtbox) {
		if len(hearts) > index do unordered_remove(&hearts, index)
		add_hexagon_to_clump(&player.clump, heart.type)
		player_action_list.last_hexagon_found = heart.type
		hexagon_found_time = 5
		play_sound(merge, 0.7)
		
		if heart.type == .HEALTH_PAD || heart.type == .ICE_BALL || heart.type == .FIREBALL || heart.type == .BLACK_HOLE {
			player_action_list.found_spell = true
		} else do player_action_list.found_upgrade = true
	}
}

draw_hearts :: proc() { for heart in hearts do draw_heart(heart) }

draw_heart :: proc(heart: Hexagon_Heart) {
	rl.DrawCircleGradient(heart.center, 40, rl.SKYBLUE, rl.BLANK)
	draw_hexagon(heart.hexagon)
	if debug_on do draw_debug_text(heart.center, "%.1f, %.1f", heart.vel.x, heart.vel.y)
}