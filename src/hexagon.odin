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
	center: rl.Vector2, // Hexagon center, should be rotated beforehand
	rot: f32,
	hurtbox: rl.Rectangle,
}

GetHexagonHurtBox :: proc(center: rl.Vector2) -> rl.Rectangle {
	SIZE :: HEXAGON_SIZE * 3 / 4
	return rl.Rectangle{center.x - SIZE / 2, center.y - SIZE / 2, SIZE, SIZE}
}

DrawHexagon :: proc(hex: Hexagon) {
	texture := hexagon_textures[hex.type]
	src := rl.Rectangle{0, 0, f32(texture.width), f32(texture.height)}

	// Note that hex.center should already be rotated, so we don't need to apply
	// any modifications.
	dest := rl.Rectangle{hex.center.x, hex.center.y, HEXAGON_SIZE, HEXAGON_SIZE}

	// Since dest takes into account the fact that hex.center is rotated, rotating around
	// the middle of it works!
	rl.DrawTexturePro(texture, src, dest, HEXAGON_SIZE / 2, hex.rot, rl.WHITE)
	
	rl.DrawRectangleLinesEx(hex.hurtbox, 1, rl.RED)
	rl.DrawCircleV(hex.center, 3, rl.RED)
}

LoadHexagons :: proc() {
	hexagon_textures = {
		.BLANK = rl.LoadTexture("res/hexagon/blank.png"),
	}
}

UnloadHexagons :: proc() {
	for texture in hexagon_textures do rl.UnloadTexture(texture)
}