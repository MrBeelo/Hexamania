package main

import rl "vendor:raylib"
import "core:strings"

// The size of the hexagon destination texture, which also happens to be its diameter
HEXAGON_SIZE :: f32(32) 

// The side length of the hexagon
HEXAGON_SIDE_LENGTH :: HEXAGON_SIZE / 2 

// The hexagon's height. Note that the hexagon in the texture doesn't reach the
// top/bottom boundaries, so using HEXAGON_SIZE would make the offsets weird.
HEXAGON_HEIGHT :: HEXAGON_SIDE_LENGTH * 1.73 // sqrt(3) ~= 1.73

hexagon_textures: [HexagonType]rl.Texture2D

HexagonType :: enum {
	RIFLE,
	RIFLE_UPGRADE_FIRE_RATE,
	RIFLE_UPGRADE_PELLET_SPEED,
	RIFLE_UPGRADE_DAMAGE,
	HEALTH_PAD,
	HEALTH_PAD_UPGRADE_HEAL_AMOUNT,
	HEALTH_PAD_UPGRADE_SIZE,
	HEALTH_PAD_UPGRADE_TIME,
	ICE_BALL,
	ICE_BALL_UPGRADE_RANGE,
	ICE_BALL_UPGRADE_FLOOR_SIZE,
	ICE_BALL_UPGRADE_FREEZE_TIME,
	FIREBALL,
	FIREBALL_UPGRADE_SIZE,
	FIREBALL_UPGRADE_TIME,
	FIREBALL_UPGRADE_DAMAGE,
}

Hexagon :: struct {
	type: HexagonType,
	center: rl.Vector2, // Hexagon center, should be rotated beforehand
	rot: f32,
	hurtbox: rl.Rectangle,
}

GetHexagonHurtBox :: proc(center: rl.Vector2) -> rl.Rectangle {
	SIZE :: HEXAGON_SIZE * 7 / 8
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

	if debug_on {
		rl.DrawRectangleLinesEx(hex.hurtbox, 1, rl.RED)
		rl.DrawCircleV(hex.center, 3, rl.RED)
	}
}

LoadHexagon :: proc(name: string) -> rl.Texture2D { 
	return rl.LoadTexture(strings.clone_to_cstring(strings.concatenate({"res/hexagon/", name, ".png"}))) 
}

LoadHexagons :: proc() {
	hexagon_textures = {
		.RIFLE = LoadHexagon("rifle"),
		.RIFLE_UPGRADE_FIRE_RATE = LoadHexagon("rifle_upgrade_fire_rate"),
		.RIFLE_UPGRADE_PELLET_SPEED = LoadHexagon("rifle_upgrade_pellet_speed"),
		.RIFLE_UPGRADE_DAMAGE = LoadHexagon("rifle_upgrade_damage"),
		.HEALTH_PAD = LoadHexagon("health_pad"),
		.HEALTH_PAD_UPGRADE_HEAL_AMOUNT = LoadHexagon("health_pad_upgrade_heal_amount"),
		.HEALTH_PAD_UPGRADE_SIZE = LoadHexagon("health_pad_upgrade_size"),
		.HEALTH_PAD_UPGRADE_TIME = LoadHexagon("health_pad_upgrade_time"),
		.ICE_BALL = LoadHexagon("ice_ball"),
		.ICE_BALL_UPGRADE_RANGE = LoadHexagon("ice_ball_upgrade_range"),
		.ICE_BALL_UPGRADE_FLOOR_SIZE = LoadHexagon("ice_ball_upgrade_floor_size"),
		.ICE_BALL_UPGRADE_FREEZE_TIME = LoadHexagon("ice_ball_upgrade_freeze_time"),
		.FIREBALL = LoadHexagon("fireball"),
		.FIREBALL_UPGRADE_SIZE = LoadHexagon("fireball_upgrade_size"),
		.FIREBALL_UPGRADE_TIME = LoadHexagon("fireball_upgrade_time"),
		.FIREBALL_UPGRADE_DAMAGE = LoadHexagon("fireball_upgrade_damage"),
	}
}

UnloadHexagons :: proc() {
	for texture in hexagon_textures do rl.UnloadTexture(texture)
}