package main

import rl "vendor:raylib"
import "core:math"
import "core:math/rand"

HEART_DECELERATION :: 5 * 60
hearts: [dynamic]HexagonHeart

HexagonHeart :: struct {
	using hexagon: Hexagon,
	vel: rl.Vector2,
	time_alive: f32,
}

ThrowHeart :: proc(pos: rl.Vector2, type: HexagonType) {
	vel_x := RangeRand({100, 150})
	vel_y := RangeRand({100, 150})
	
	append(&hearts, HexagonHeart{{type, pos, 0, {}}, {vel_x, vel_y}, 0})
}

ThrowRandomHeart :: proc(pos: rl.Vector2) {
	type := rand.choice_enum(HexagonType)
	ThrowHeart(pos, type)
}

UpdateHexagonHearts :: proc() { for &heart, index in hearts do UpdateHexagonHeart(&heart, index) }

UpdateHexagonHeart :: proc(heart: ^HexagonHeart, index: int) {
	heart.time_alive += rl.GetFrameTime()
	heart.rot += rl.GetFrameTime() * (math.abs(heart.vel.x) + math.abs(heart.vel.y)) / 2
	
	heart.center += heart.vel * rl.GetFrameTime()
	Accelerate(&heart.vel.x, 0, HEART_DECELERATION)
	Accelerate(&heart.vel.y, 0, HEART_DECELERATION)

	DEADZONE :: f32(3)
	if math.abs(heart.vel.x) < DEADZONE do heart.vel.x = 0
	if math.abs(heart.vel.y) < DEADZONE do heart.vel.y = 0
	
	heart.hurtbox = GetHexagonHurtBox(heart.center)

	lowest_dist := f32(9999)
	closest_box: rl.Rectangle
	for hexagon in player.clump.hexagons {
		dist := rl.Vector2Distance(heart.center, hexagon.center)
		if dist < lowest_dist {
			lowest_dist = dist
			closest_box = hexagon.hurtbox
		}
	}
	
	heart.vel = VelocityFrom2Points(heart.center, player.pos) * (1 + heart.time_alive) * 30
	
	if rl.CheckCollisionRecs(closest_box, heart.hurtbox) {
		if len(hearts) > index do unordered_remove(&hearts, index)
		AddHexagonToClump(&player.clump, heart.type)
		last_hexagon_found = heart.type
		hexagon_found_time = 5
		rl.PlaySound(merge)
		
		if heart.type == .HEALTH_PAD || heart.type == .ICE_BALL || heart.type == .FIREBALL || heart.type == .BLACK_HOLE {
			has_found_spell = true
		} else do has_found_upgrade = true
	}
}

DrawHexagonHearts :: proc() { for heart in hearts do DrawHexagonHeart(heart) }

DrawHexagonHeart :: proc(heart: HexagonHeart) {
	rl.DrawCircleGradient(heart.center, 40, rl.SKYBLUE, rl.BLANK)
	DrawHexagon(heart.hexagon)
	if debug_on do DrawDebugText(heart.center, "%.1f, %.1f", heart.vel.x, heart.vel.y)
}