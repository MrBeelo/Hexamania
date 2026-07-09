package main

import rl "vendor:raylib"

BACKGROUND_SIZE :: f32(1024)
background: rl.Texture2D

LoadBackground :: proc() {
	background = rl.LoadTexture("res/background.png")
}

UnloadBackground :: proc() {
	rl.UnloadTexture(background)
}

DrawBackground :: proc() {
	src := rl.Rectangle{0, 0, f32(background.width), f32(background.height)}
	start_pos := rl.Vector2{ RoundDownToNearest(player.pos.x, BACKGROUND_SIZE), RoundDownToNearest(player.pos.y, BACKGROUND_SIZE) }
	spots := GetAllBackgroundSpots(start_pos, BACKGROUND_SIZE)
	for spot in spots {
		dest := rl.Rectangle{spot.x, spot.y, BACKGROUND_SIZE, BACKGROUND_SIZE}
		rl.DrawTexturePro(background, src, dest, {}, 0, rl.WHITE)
	}
}

GetAllBackgroundSpots :: proc(start: rl.Vector2, multiple: f32) -> [9]rl.Vector2 {
	result := [9]rl.Vector2{
		{-1, -1},
		{-1, 0},
		{-1, 1},
		{0, -1},
		{0, 0},
		{0, 1},
		{1, -1},
		{1, 0},
		{1, 1},
	}

	result *= multiple
	for &pos in result do pos += start
	return result
}