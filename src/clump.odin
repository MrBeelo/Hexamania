package main

import rl "vendor:raylib"
import "core:math"

MAX_HEXAGONS :: 1 + 6 + 12 + 18
SPEED :: 15 * 60
ACCELERATION :: 5 * 60

HexagonClump :: struct {
	hexagon_types: []HexagonType,
	pos: rl.Vector2,
	vel: rl.Vector2,
	rot: f32,
}

NewHexagonClump :: proc(hexagon_types: []HexagonType, center: rl.Vector2) -> HexagonClump {
	if len(hexagon_types) > MAX_HEXAGONS do return HexagonClump{}
	new_hexagon_types := make([]HexagonType, len(hexagon_types))
	copy(new_hexagon_types, hexagon_types)
	return HexagonClump{new_hexagon_types, center, 0, 0}
}

AddHexagonToClump :: proc(clump: ^HexagonClump, type: HexagonType) {
	len := len(clump.hexagon_types)
	if len >= MAX_HEXAGONS do return
	new_hexagon_types := make([]HexagonType, len + 1)
	copy(new_hexagon_types, clump.hexagon_types)
	new_hexagon_types[len] = type
	clump.hexagon_types = new_hexagon_types
}

UpdateHexagonClump :: proc(clump: ^HexagonClump) {
	clump.rot += rl.GetFrameTime() * (math.abs(clump.vel.x) + math.abs(clump.vel.y)) / 2	

	clump.vel.x = math.clamp(clump.vel.x, -SPEED, SPEED)
	clump.vel.y = math.clamp(clump.vel.y, -SPEED, SPEED)

	clump.pos += clump.vel * rl.GetFrameTime()
}

DrawHexagonClump :: proc(clump: HexagonClump) {
	for hexagon in GetClumpHexagons(clump) do DrawHexagon(hexagon)
}

GetClumpHexagons :: proc(clump: HexagonClump) -> []Hexagon {
	hexagons := make([]Hexagon, len(clump.hexagon_types))
	for hexagon_type, index in clump.hexagon_types {
		offset := GetHexagonOffset(index)

		// Calculate the local_center and origin_center, based on the offset
		local_center := clump.pos + offset
		absolute_center_offset := GetAbsoluteCenterOffset(len(clump.hexagon_types))
		origin_center := absolute_center_offset - offset

		// Correction explained below
		pre_absolute_center := GetPreAbsoluteCenter(clump)
		diff := clump.pos - pre_absolute_center
		local_center += diff

		absolute_center := pre_absolute_center - absolute_center_offset
		hurtbox := GetHexagonHurtBox(local_center, absolute_center, clump.rot)
		
		hexagon := Hexagon{hexagon_type, local_center, origin_center, clump.rot, hurtbox}
		hexagons[index] = hexagon
	}

	return hexagons
}

// As explained below, adding these two values gives us the absolute center,
// this is used for the rotation of every hexagon. Note that this is NOT In the same position
// as the hex center, so it looks a bit off. To fix this, we take the difference from
// those 2 values, and add it to every hexagon's local_center.
GetPreAbsoluteCenter :: proc(clump: HexagonClump) -> rl.Vector2 {
	return GetAbsoluteCenterOffset(len(clump.hexagon_types)) + clump.pos
}

// From every hexagon in the clump, all the positions are averaged
// to get the absolute center offset. This is the offset from
// the middle_hex_center, so adding these (which we do above)
// will give us the absolute center
GetAbsoluteCenterOffset :: proc(hexagon_count: int) -> rl.Vector2 {
	if hexagon_count == 0 do return {}
	offset: rl.Vector2
	for i in 0..<hexagon_count do offset += GetHexagonOffset(i)
	offset /= f32(hexagon_count)
	return offset
}

// Gets the offset from the middle_hex_center to any particular hexagon.
// Of course, the first hexagon is the middle, so it returns {0, 0}.
// The offsets for the others are calculated in a clockwise rotation.
// We parse the offset (which is currently hardcoded) in a simple integer format
// and convert it to real world space using HEXAGON_HEIGHT and HEXAGON_SIZE
// 
// VERY IMPORTANT: coord_offset.y is flipped, as coordinate system in windowing is
// usually "Y increases the downer you go", while I prefer the normal math system, which
// is the opposite.
GetHexagonOffset :: proc(index: int) -> rl.Vector2 {
	coord_offset := hexagon_coord_offsets[index]
	return rl.Vector2{HEXAGON_HEIGHT * coord_offset.x, HEXAGON_SIZE * -coord_offset.y}
}

// Hardcoded offsets, explained above
// As stated above, Y values are flipped!
// I could have made a better system of calculating the offsets rather than hardcoding,
// but I think I'd spend too much time on that XD
hexagon_coord_offsets := [MAX_HEXAGONS]rl.Vector2 {
	// Middle Hexagon, should ALWAYS be {0, 0}
	0 = {0, 0},
		
	// Shell 1 Hexagons (amount: 6)
	1 = {0, 1},
	2 = {1, 0.5},
	3 = {1, -0.5},
	4 = {0, -1},
	5 = {-1, -0.5},
	6 = {-1, 0.5},

	// Shell 2 Hexagons (amount: 12)
	7 = {0, 2},
	8 = {1, 1.5},
	9 = {2, 1},
	10 = {2, 0},
	11 = {2, -1},
	12 = {1, -1.5},
	13 = {0, -2},
	14 = {-1, -1.5},
	15 = {-2, -1},
	16 = {-2, 0},
	17 = {-2, 1},
	18 = {-1, 1.5},

	// Shell 3 Hexagons (amount: 18)
	19 = {0, 3},
	20 = {1, 2.5},
	21 = {2, 2},
	22 = {3, 1.5},
	23 = {3, 0.5},
	24 = {3, -0.5},
	25 = {3, -1.5},
	26 = {2, -2},
	27 = {1, -2.5},
	28 = {0, -3},
	29 = {-1, -2.5},
	30 = {-2, -2},
	31 = {-3, -1.5},
	32 = {-3, -0.5},
	33 = {-3, 0.5},
	34 = {-3, 1.5},
	35 = {-2, 2},
	36 = {-1, 2.5},
}