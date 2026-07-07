package main

import rl "vendor:raylib"

hearts: [dynamic]HexagonHeart

HexagonHeart :: struct {
	using hexagon: Hexagon,
}

UpdateHexagonHearts :: proc() { for &heart, index in hearts do UpdateHexagonHeart(&heart, index) }

UpdateHexagonHeart :: proc(heart: ^HexagonHeart, index: int) {
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