package main

import rl "vendor:raylib"
import "core:math"
import "core:math/rand"

HEART_DECELERATION :: 5 * 60
HEART_VEL_RANGE :: rl.Vector2{100, 150}
hearts: [dynamic]HexagonHeart

HexagonHeart :: struct {
	using hexagon: Hexagon,
	vel: rl.Vector2,
}

ThrowRandomHeart :: proc(pos: rl.Vector2) {
	type := rand.choice_enum(HexagonType)

	diff := HEART_VEL_RANGE.y - HEART_VEL_RANGE.x
	vel_x := rand.float32_range(-diff, diff)
	vel_y := rand.float32_range(-diff, diff)
	vel_x += HEART_VEL_RANGE.x if vel_x >= 0 else -HEART_VEL_RANGE.x
	vel_y += HEART_VEL_RANGE.x if vel_y >= 0 else -HEART_VEL_RANGE.x
	
	append(&hearts, HexagonHeart{{type, pos, 0, {}}, {vel_x, vel_y}})
}

UpdateHexagonHearts :: proc() { for &heart, index in hearts do UpdateHexagonHeart(&heart, index) }

UpdateHexagonHeart :: proc(heart: ^HexagonHeart, index: int) {
	heart.rot += rl.GetFrameTime() * (math.abs(heart.vel.x) + math.abs(heart.vel.y)) / 2
	
	heart.center += heart.vel * rl.GetFrameTime()
	Accelerate(&heart.vel.x, 0, HEART_DECELERATION)
	Accelerate(&heart.vel.y, 0, HEART_DECELERATION)

	DEADZONE :: f32(3)
	if math.abs(heart.vel.x) < DEADZONE do heart.vel.x = 0
	if math.abs(heart.vel.y) < DEADZONE do heart.vel.y = 0
	
	heart.hurtbox = GetHexagonHurtBox(heart.center)
	for hexagon in GetClumpHexagons(player.clump) do if rl.Vector2Distance(hexagon.center, heart.center) < 100 {
		if rl.CheckCollisionRecs(hexagon.hurtbox, heart.hurtbox) {
			unordered_remove(&hearts, index)
			AddHexagonToClump(&player.clump, heart.type)
		}
	}
}

DrawHexagonHearts :: proc() { for heart in hearts do DrawHexagonHeart(heart) }

DrawHexagonHeart :: proc(heart: HexagonHeart) {
	rl.DrawCircleGradient(heart.center, 40, rl.SKYBLUE, rl.BLANK)
	DrawHexagon(heart.hexagon)
}