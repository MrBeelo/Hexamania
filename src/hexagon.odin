package main

import rl "vendor:raylib"

// The size of the hexagon destination texture, which also happens to be its diameter
HEXAGON_SIZE :: f32(32) 

// The side length of the hexagon
HEXAGON_SIDE_LENGTH :: HEXAGON_SIZE / 2 

// The hexagon's height. Note that the hexagon in the texture doesn't reach the
// top/bottom boundaries, so using HEXAGON_SIZE would make the offsets weird.
HEXAGON_HEIGHT :: HEXAGON_SIDE_LENGTH * 1.73 // sqrt(3) ~= 1.73

hexagon_textures: [HexagonType]rl.Texture2D

HexagonType :: enum {
	BLANK,
}

Hexagon :: struct {
	type: HexagonType,
	local_center: rl.Vector2,
	origin_center: rl.Vector2,
	rot: f32,
}

DrawHexagon :: proc(hex: Hexagon) {
	texture := hexagon_textures[hex.type]
	src := rl.Rectangle{0, 0, f32(texture.width), f32(texture.height)}

	// Origin is definitely needed here so that rotations work normally.
	origin := hex.origin_center + HEXAGON_SIZE / 2
	dest := rl.Rectangle{hex.local_center.x - HEXAGON_SIZE / 2 + origin.x, hex.local_center.y - HEXAGON_SIZE / 2 + origin.y, 
		HEXAGON_SIZE, HEXAGON_SIZE}
	
	rl.DrawTexturePro(texture, src, dest, origin, hex.rot, rl.WHITE)
}

LoadHexagons :: proc() {
	hexagon_textures = {
		.BLANK = rl.LoadTexture("res/blank.png"),
	}
}

UnloadHexagons :: proc() {
	for texture in hexagon_textures do rl.UnloadTexture(texture)
}