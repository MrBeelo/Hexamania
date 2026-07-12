package main

import rl "vendor:raylib"
import "core:math"
import "core:crypto"
import "core:encoding/uuid"

MAX_LEVEL :: 4
MAX_HEXAGONS :: 1 + 6 + 12 + 18
BASE_MAX_HEALTH :: f32(100)
MAX_SPRINT_SECS :: f32(5)
REGEN_SPRINT_TIME :: f32(2.5)

// Clumps function as entities, hence their "health" and "uuid" fields.
HexagonClump :: struct {
	hexagon_types: []HexagonType,
	pos: rl.Vector2,
	vel: rl.Vector2,
	rot: f32,
	health: f32,
	uuid: uuid.Identifier,
	spr: SprintPackage,
	health_regen: Timer,
	grace_period: f32,
	attacker: ^HexagonClump,
	rifle_delay: f32,
	frozen_time_left: f32,
	burning: struct{ damage_timer: Timer, time_left: f32, damage: f32 },
	spell_cooldowns: [SpellType]f32,
	kill_happiness_time: f32,
	dead_time: f32,
	can_shoot: bool,
	collision_grace_period: f32,
}

// Everything that has to do with sprinting.
SprintPackage :: struct {
	sprinting: bool,
	sprint_secs: f32,
	time_since_last_sprint: f32,
}

GetMaxHealth :: proc(hexagons: int) -> f32 {
	return BASE_MAX_HEALTH + (f32(hexagons) - 1) * 5
}

NewHexagonClump :: proc(hexagon_types: []HexagonType, center: rl.Vector2, vel := rl.Vector2{}, rot := f32(0)) -> HexagonClump {
	if len(hexagon_types) > MAX_HEXAGONS do return HexagonClump{}

	// Copy the hexagon_types parameter to clump
	new_hexagon_types := make([]HexagonType, len(hexagon_types))
	copy(new_hexagon_types, hexagon_types)

	// Generate entity UUID
	context.random_generator = crypto.random_generator()
	id := uuid.generate_v7()

	// Health Regen Timer
	health_regen := NewTimer(5, true, true)
	health := GetMaxHealth(len(hexagon_types))
	
	return HexagonClump{new_hexagon_types, center, 0, 0, health, id, {false, 5, 5}, health_regen, 
		0, nil, 0, 0, {}, {}, 0, 0, true, 0}
}

AddHexagonToClump :: proc(clump: ^HexagonClump, type: HexagonType) {
	len := len(clump.hexagon_types)
	if len >= MAX_HEXAGONS do return

	// The slice the clump currently has is 1 type short, so we make a new
	// one and copy it.
	new_hexagon_types := make([]HexagonType, len + 1)
	copy(new_hexagon_types, clump.hexagon_types)
	new_hexagon_types[len] = type
	clump.hexagon_types = new_hexagon_types
}

// Returns how many of each type the clump contains
GetHexagonTypeAmounts :: proc(clump: HexagonClump) -> [HexagonType]int {
	result: [HexagonType]int
	for type in clump.hexagon_types do result[type] += 1
	return result
}

// Checks if any of the clump's hexagons intersect with the rectangle
ClumpIntersectsRect :: proc(clump: HexagonClump, rect: rl.Rectangle) -> bool {
	for hexagon in GetClumpHexagons(clump) {
	 	if rl.CheckCollisionRecs(rect, hexagon.hurtbox) do return true
	}
	return false
}

// Ditto, but circle :O
ClumpIntersectsCircle :: proc(clump: HexagonClump, center: rl.Vector2, radius: f32) -> bool {
	for hexagon in GetClumpHexagons(clump) {
	 	if rl.CheckCollisionCircleRec(center, radius, hexagon.hurtbox) do return true
	}
	return false
}

UpdateHexagonClump :: proc(clump: ^HexagonClump) {
	clump.can_shoot = true
	if clump.frozen_time_left > 0 do clump.can_shoot = false
	
	clump.rot += rl.GetFrameTime() * (math.abs(clump.vel.x) + math.abs(clump.vel.y)) / 2

	// Health Regen Stuff
	UpdateTimer(&clump.health_regen)
	if clump.health_regen.ding do HealClump(clump, 2)
	clump.health = math.clamp(clump.health, 0, GetMaxHealth(len(clump.hexagon_types)))
	if clump.grace_period > 0 do clump.grace_period -= rl.GetFrameTime()
	if clump.collision_grace_period > 0 do clump.collision_grace_period -= rl.GetFrameTime()

	// Sprinting logic
	if clump.spr.sprinting {
		clump.spr.sprint_secs -= rl.GetFrameTime()
		clump.spr.time_since_last_sprint = 0
	} else {
		clump.spr.time_since_last_sprint += rl.GetFrameTime()
	}

	if clump.spr.sprint_secs <= 0 do clump.spr.sprinting = false
	if clump.spr.time_since_last_sprint > REGEN_SPRINT_TIME do clump.spr.sprint_secs += rl.GetFrameTime()
	clump.spr.sprint_secs = math.clamp(clump.spr.sprint_secs, 0, MAX_SPRINT_SECS)

	// Handle spells
	if clump.frozen_time_left > 0 do clump.frozen_time_left -= rl.GetFrameTime()
	clump.frozen_time_left = math.max(clump.frozen_time_left, 0)

	UpdateTimer(&clump.burning.damage_timer)
	if clump.burning.time_left > 0 {
		clump.burning.time_left -= rl.GetFrameTime()
		if clump.burning.damage_timer.ding do DamageClumpNoAttacker(clump, clump.burning.damage)
	}

	if clump.rifle_delay > 0 do clump.rifle_delay -= rl.GetFrameTime()
	clump.rifle_delay = math.max(clump.rifle_delay, 0)

	for spell in SpellType do if clump.spell_cooldowns[spell] > 0 do clump.spell_cooldowns[spell] -= rl.GetFrameTime()
	for spell in SpellType do clump.spell_cooldowns[spell] = math.max(clump.spell_cooldowns[spell], 0)

	// Expressions
	if clump.kill_happiness_time > 0 do clump.kill_happiness_time -= rl.GetFrameTime()
	clump.kill_happiness_time = math.max(clump.kill_happiness_time, 0)

	// Dying stuff
	if clump.health <= 0 do clump.dead_time += rl.GetFrameTime()

	// Collision logic
	HandleClumpCollisions(clump)

	// Final velocity addition (should probably be last)
	if clump.frozen_time_left <= 0 && clump.dead_time <= 0 do clump.pos += clump.vel * rl.GetFrameTime() * (1.5 if clump.spr.sprinting else 1)
}

DrawHexagonClump :: proc(clump: HexagonClump) {
	overlay: Maybe(HexagonOverlay) = nil
	if clump.frozen_time_left > 0 do overlay = HexagonFrozenOverlay{}
	if clump.burning.time_left > 0 do overlay = HexagonBurningOverlay{}

	opacity: u8 = 100 if clump.grace_period > 0 else 255
	if clump.dead_time > 0 do opacity = u8(255 * (1 - clump.dead_time * 2))
	
	for hexagon in GetClumpHexagons(clump) do DrawHexagon(hexagon, opacity, overlay)
	
	if debug_on do rl.DrawCircleV(clump.pos, 2, rl.BLUE)
}

// This is a broken buggy mess. I don't have time to implement good collisions
// I don't care anymore.

HandleClumpCollisions :: proc(clump: ^HexagonClump) {
	if clump.collision_grace_period > 0 do return
	if clump.dead_time > 0 do return
	for enemy_clump in GetAllClumps() {
		if enemy_clump.collision_grace_period > 0 do continue
		if enemy_clump.dead_time > 0 do continue
		if clump.uuid == enemy_clump.uuid do continue
		
		for hexagon in GetClumpHexagons(clump^) do for enemy_hexagon in GetClumpHexagons(enemy_clump^) {
			if rl.Vector2Distance(hexagon.center, enemy_hexagon.center) > 100 do continue
			if !rl.CheckCollisionRecs(hexagon.hurtbox, enemy_hexagon.hurtbox) do continue
			DamageClump(clump, 2, enemy_clump)
			DamageClump(enemy_clump, 2, clump)
			clump.collision_grace_period = 0.5
			enemy_clump.collision_grace_period = 0.5
		}
	}
}


GetAllClumps :: proc() -> []^HexagonClump {
	result := make([]^HexagonClump, len(enemies) + 1)
	for &enemy, index in enemies do result[index] = &enemy.clump
	result[len(enemies)] = &player.clump
	return result
}

GetClumpFromUUID :: proc(id: uuid.Identifier) -> ^HexagonClump {
	for clump in GetAllClumps() do if clump.uuid == id do return clump
	return nil
}

DamageClump :: proc(clump: ^HexagonClump, amount: f32, attacker: ^HexagonClump) {
	if clump.grace_period > 0 do return

	multiplier := f32(1)
	if attacker.uuid == player.uuid && clump.uuid != player.uuid {
		if player.bound_powerups[.DAMAGE].time_remaining > 0 do multiplier = player.bound_powerups[.DAMAGE].value
	}
	
	clump.health -= amount * multiplier
	clump.grace_period = 0.15
	clump.attacker = attacker

	if clump.health <= 0 {
		attacker.kill_happiness_time = 2
	 	if attacker.uuid == player.uuid do points += len(clump.hexagon_types)
	}
}

DamageClumpNoAttacker :: proc(clump: ^HexagonClump, amount: f32) {
	if clump.grace_period > 0 do return
	clump.health -= amount
	clump.grace_period = 0.15
}

HealClump :: proc(clump: ^HexagonClump, amount: f32) {
	if clump.health <= 0 do return
	clump.health += amount
}

GetClumpHexagons :: proc(clump: HexagonClump) -> []Hexagon {
	hexagons := make([]Hexagon, len(clump.hexagon_types))
	for hexagon_type, index in clump.hexagon_types {
		// First we get the local offset from the middle hexagon
		offset := GetHexagonOffset(index)

		// We get the average offset, so we can center the clump properly (around clump.pos)
		average_offset := GetAverageOffset(len(clump.hexagon_types))

		// Local center here is the non rotated center of the hexagon
		local_center := clump.pos + (offset - average_offset) * math.max(1 + clump.dead_time * 2, 0)

		// Rotated center is the actual center of the hexagon
		rotated_center := RotatePoint(local_center, clump.pos, clump.rot)
		
		hurtbox := GetHexagonHurtBox(rotated_center)
		hexagon := Hexagon{hexagon_type, rotated_center, clump.rot, hurtbox}
		if len(hexagons) > index do hexagons[index] = hexagon
	}

	return hexagons
}

Accelerate :: proc(value: ^f32, target: f32, acceleration: f32) {
	if value^ > target do value^ -= f32(acceleration) * rl.GetFrameTime()
	if value^ < target do value^ += f32(acceleration) * rl.GetFrameTime()
}

// Get a short part of the clump's UUID, as a string
ShortUUID :: proc(id: uuid.Identifier) -> string {
	return string(rl.TextFormat("%d%d%d%d", id[8], id[9], id[10], id[11]))
}

// From every hexagon in the clump, all the positions are averaged
// to get the average offset. If we didn't calculate this, the center of the
// clump would be the middle hex's center, which we don't always want.
GetAverageOffset :: proc(hexagon_count: int) -> rl.Vector2 {
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