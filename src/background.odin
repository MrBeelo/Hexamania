package main

import rl "vendor:raylib"
import "core:math"

BACKGROUND_SIZE :: rl.Vector2{1024, 1024}
BACKGROUND_DURATION :: f32(20)
background: rl.Texture2D

LoadBackground :: proc() {
	background = rl.LoadTexture("res/background.png")
	rl.SetTextureFilter(background, .BILINEAR)
}

UnloadBackground :: proc() {
	rl.UnloadTexture(background)
}

DrawGameBackground :: proc() {	
	start_pos := rl.Vector2{ RoundDownToNearest(player.pos.x, BACKGROUND_SIZE.x), RoundDownToNearest(player.pos.y, BACKGROUND_SIZE.y) }
	spots := GetAllBackgroundSpots(start_pos, BACKGROUND_SIZE)
	for spot in spots {
		dest := rl.Rectangle{spot.x, spot.y, BACKGROUND_SIZE.x, BACKGROUND_SIZE.y}
		DrawBackground(dest, GetBackgroundColors())
	}
}

DrawMainMenuBackground :: proc() {
	for i in 0..=1 {
		dest := rl.Rectangle{0 - math.mod_f32(f32(rl.GetTime() * 4), BACKGROUND_SIZE.x) + f32(i) * BACKGROUND_SIZE.x, 
			0, BACKGROUND_SIZE.x, BACKGROUND_SIZE.y}
		DrawBackground(dest, GetBackgroundColors())
	}
}

DrawBackground :: proc(dest: rl.Rectangle, main_color: rl.Color, hexa_color: rl.Color) {
	src := rl.Rectangle{0, 0, f32(background.width), f32(background.height)}
	rl.DrawRectangleRec(dest, main_color)
	rl.DrawTexturePro(background, src, dest, {}, 0, hexa_color)
}

GetBackgroundColors :: proc(duration := BACKGROUND_DURATION) -> (main: rl.Color, hexa: rl.Color) {
	time := f32(rl.GetTime())
	time = math.mod_f32(time, duration)
	factor := math.sin(rl.PI * time / duration)
	return rl.ColorLerp({0, 4, 56, 255}, {24, 0, 56, 255}, factor), rl.ColorLerp({0, 8, 109, 255}, {41, 0, 95, 255}, factor)
}

GetAllBackgroundSpots :: proc(start: rl.Vector2, multiple: rl.Vector2) -> [9]rl.Vector2 {
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

	for &pair in result do pair *= multiple
	for &pos in result do pos += start
	return result
}