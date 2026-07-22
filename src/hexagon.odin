package main

import rl "vendor:raylib"
import "core:math"

// The size of the hexagon destination texture, which also happens to be its diameter
HEXAGON_SIZE :: f32(32) 

// The side length of the hexagon
HEXAGON_SIDE_LENGTH :: HEXAGON_SIZE / 2 

// The hexagon's height. Note that the hexagon in the texture doesn't reach the
// top/bottom boundaries, so using HEXAGON_SIZE would make the offsets weird.
HEXAGON_HEIGHT :: HEXAGON_SIDE_LENGTH * 1.73 // sqrt(3) ~= 1.73

hexagon_sheet: rl.Texture2D
hexagon_frozen_texture: rl.Texture2D
hexagon_burning_texture_sheet: rl.Texture2D

HexagonType :: enum {
	RIFLE,
	RIFLE_UPGRADE_PELLET_SPEED,
	RIFLE_UPGRADE_FIRE_RATE,
	RIFLE_UPGRADE_DAMAGE,
	HEALTH_PAD,
	HEALTH_PAD_UPGRADE_SIZE,
	HEALTH_PAD_UPGRADE_TIME,
	HEALTH_PAD_UPGRADE_HEAL_AMOUNT,
	ICE_BALL,
	ICE_BALL_UPGRADE_SIZE,
	ICE_BALL_UPGRADE_FREEZE_TIME,
	ICE_BALL_UPGRADE_RANGE,
	FIREBALL,
	FIREBALL_UPGRADE_SIZE,
	FIREBALL_UPGRADE_BURN_TIME,
	FIREBALL_UPGRADE_DAMAGE,
	BLACK_HOLE,
	BLACK_HOLE_UPGRADE_SIZE,
	BLACK_HOLE_UPGRADE_TIME,
	BLACK_HOLE_UPGRADE_SUCTION_POWER,
}

HexagonFrozenOverlay :: struct {}
HexagonBurningOverlay :: struct {}
HexagonOverlay :: union {
	HexagonFrozenOverlay,
	HexagonBurningOverlay,
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

DrawHexagon :: proc(hex: Hexagon, opacity := u8(255), overlay: Maybe(HexagonOverlay) = nil, ) {
	src := GetHexagonTextureSource(hex.type)

	// Note that hex.center should already be rotated, so we don't need to apply
	// any modifications.
	dest := rl.Rectangle{hex.center.x, hex.center.y, HEXAGON_SIZE, HEXAGON_SIZE}

	// Since dest takes into account the fact that hex.center is rotated, rotating around
	// the middle of it works!
	color := rl.Color{255, 255, 255, opacity}
	rl.DrawTexturePro(hexagon_sheet, src, dest, HEXAGON_SIZE / 2, hex.rot, color)

	// Draw overlays
	if overlay != nil do switch o in overlay.? {
	case HexagonFrozenOverlay: {
		frozen_texture_src := rl.Rectangle{0, 0, f32(hexagon_frozen_texture.width), f32(hexagon_frozen_texture.height)}
		rl.DrawTexturePro(hexagon_frozen_texture, frozen_texture_src, dest, HEXAGON_SIZE / 2, hex.rot, color)
	}
	case HexagonBurningOverlay: {
		for i in 0..=2 {
			BURN_TEXTURE_SRC_SIZE :: 256
			burn_texture_src := rl.Rectangle{f32(i) * BURN_TEXTURE_SRC_SIZE, 0, BURN_TEXTURE_SRC_SIZE, BURN_TEXTURE_SRC_SIZE}
			burn_color := GetBurningOverlayColor(f32(i) / 3, opacity)
			rl.DrawTexturePro(hexagon_burning_texture_sheet, burn_texture_src, dest, HEXAGON_SIZE / 2, hex.rot, burn_color)
		}
	}
	}

	if DEBUG_ON {
		rl.DrawRectangleLinesEx(hex.hurtbox, 1, rl.RED)
		rl.DrawCircleV(hex.center, 3, rl.RED)
	}
}

GetBurningOverlayColor :: proc(time_delay: f32, opacity := u8(255)) -> rl.Color {
	time := f32(rl.GetTime()) + time_delay
	time = math.mod_f32(time, 1)
	factor := math.sin(rl.PI * time)
	color := rl.ColorLerp(rl.RED, rl.Color{244, 60, 0, 255}, factor)
	color.a = opacity
	return color
}

LoadHexagons :: proc() {
	hexagon_sheet = rl.LoadTexture("texture/hexagon_sheet.png")
	hexagon_frozen_texture = rl.LoadTexture("texture/hexagon_frozen.png")
	hexagon_burning_texture_sheet = rl.LoadTexture("texture/hexagon_burning_sheet.png")
}

UnloadHexagons :: proc() {
	rl.UnloadTexture(hexagon_sheet)
	rl.UnloadTexture(hexagon_frozen_texture)
	rl.UnloadTexture(hexagon_burning_texture_sheet)
}

GetHexagonTextureSource :: proc(type: HexagonType) -> rl.Rectangle {
	HEXAGON_SRC_SIZE :: 256
	src_x := int(type) % 4
	src_y := math.floor_div(int(type), 4)
	src := rl.Rectangle{f32(src_x) * HEXAGON_SRC_SIZE, f32(src_y) * HEXAGON_SRC_SIZE, HEXAGON_SRC_SIZE, HEXAGON_SRC_SIZE}
	return src
}

IsUpgrade :: proc(type: HexagonType) -> bool {
	if type == .RIFLE do return false
	if type == .HEALTH_PAD do return false
	if type == .ICE_BALL do return false
	if type == .FIREBALL do return false
	if type == .BLACK_HOLE do return false
	return true
}

IsSpell :: proc(type: HexagonType) -> bool {
	return !IsUpgrade(type)
}

GetHexagonName :: proc(type: HexagonType) -> string {
	switch type {
	case .RIFLE: return "the Rifle"
	case .RIFLE_UPGRADE_FIRE_RATE: return "Increased fire rate"
	case .RIFLE_UPGRADE_PELLET_SPEED: return "Increased pellet speed"
	case .RIFLE_UPGRADE_DAMAGE: return "Increased pellet damage"
	case .HEALTH_PAD: return "Health Pad"
	case .HEALTH_PAD_UPGRADE_HEAL_AMOUNT: return "Increased heal amount"
	case .HEALTH_PAD_UPGRADE_SIZE: return "Increased pad size"
	case .HEALTH_PAD_UPGRADE_TIME: return "Increased duration"
	case .ICE_BALL: return "Ice Ball"
	case .ICE_BALL_UPGRADE_RANGE: return "Increased range"
	case .ICE_BALL_UPGRADE_SIZE: return "Increased size"
	case .ICE_BALL_UPGRADE_FREEZE_TIME: return "Increased freeze time"
	case .FIREBALL: return "Fireball"
	case .FIREBALL_UPGRADE_SIZE: return "Increased size"
	case .FIREBALL_UPGRADE_BURN_TIME: return "Increased duration"
	case .FIREBALL_UPGRADE_DAMAGE: return "Increased burn damage"
	case .BLACK_HOLE: return "Black Hole"
	case .BLACK_HOLE_UPGRADE_SUCTION_POWER: return "Increased suction power"
	case .BLACK_HOLE_UPGRADE_SIZE: return "Increased size"
	case .BLACK_HOLE_UPGRADE_TIME: return "Increased duration"
	}
	return "ERROR"
}

GetCorrespondingSpellAsHexagon :: proc(type: HexagonType) -> HexagonType {
	return GetHexagonTypeFromSpellType(GetSpellFromHexagonType(type))
}