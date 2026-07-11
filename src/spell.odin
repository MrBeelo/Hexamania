package main

import rl "vendor:raylib"
import "core:encoding/uuid"
import "core:math/rand"

SpellType :: enum { HEALTH_PAD, ICE_BALL, FIREBALL, BLACK_HOLE }

spells: [dynamic]Spell
Spell :: union {
	HealthPad,
	IceBall,
	Fireball,
	BlackHole,
}

UpdateSpells :: proc() {
	for &spell, index in spells do switch &s in spell {
	case HealthPad: UpdateHealthPad(&s, index)
	case IceBall: UpdateIceBall(&s, index)
	case Fireball: UpdateFireball(&s, index)
	case BlackHole: UpdateBlackHole(&s, index)
	}
}

DrawSpellsBelow :: proc() {
	for spell in spells do #partial switch s in spell {
	case HealthPad: DrawHealthPad(s)
	}
}

DrawSpellsAbove :: proc() {
	for spell in spells do #partial switch s in spell {
	case IceBall: DrawIceBall(s)
	case Fireball: DrawFireball(s)
	case BlackHole: DrawBlackHole(s)
	}
}

HasSpell :: proc(clump: HexagonClump, spell: SpellType) -> bool {
	hexagon_type_amounts := GetHexagonTypeAmounts(clump)
	switch spell {
	case .HEALTH_PAD: return hexagon_type_amounts[.HEALTH_PAD] > 0
	case .ICE_BALL: return hexagon_type_amounts[.ICE_BALL] > 0
	case .FIREBALL: return hexagon_type_amounts[.FIREBALL] > 0
	case .BLACK_HOLE: return hexagon_type_amounts[.BLACK_HOLE] > 0
	}

	return false
}

GetSpellFromHexagonType :: proc(type: HexagonType) -> Maybe(SpellType) {
	switch type {
	case .RIFLE, .RIFLE_UPGRADE_FIRE_RATE, .RIFLE_UPGRADE_PELLET_SPEED, .RIFLE_UPGRADE_DAMAGE: return nil
	case .HEALTH_PAD, .HEALTH_PAD_UPGRADE_HEAL_AMOUNT, .HEALTH_PAD_UPGRADE_SIZE, .HEALTH_PAD_UPGRADE_TIME: return .HEALTH_PAD
	case .ICE_BALL, .ICE_BALL_UPGRADE_RANGE, .ICE_BALL_UPGRADE_FLOOR_SIZE, .ICE_BALL_UPGRADE_FREEZE_TIME: return .ICE_BALL
	case .FIREBALL, .FIREBALL_UPGRADE_SIZE, .FIREBALL_UPGRADE_TIME, .FIREBALL_UPGRADE_DAMAGE: return .FIREBALL
	case .BLACK_HOLE, .BLACK_HOLE_UPGRADE_SUCTION_POWER, .BLACK_HOLE_UPGRADE_SIZE, .BLACK_HOLE_UPGRADE_TIME: return .BLACK_HOLE
	}

	return nil
}

SPELL_COOLDOWN :: f32(25)

// HEALTH PAD

HealthPad :: struct { owner: uuid.Identifier, rect: rl.Rectangle, heal_amount: f32, heal_timer: Timer, time_left: f32 }

SummonHealthPad :: proc(clump: ^HexagonClump) {
	time_left, size, heal_amount := GetHealthPadStats(GetHexagonTypeAmounts(clump^))

	rect := rl.Rectangle{clump.pos.x - size / 2, clump.pos.y - size / 2, size, size}
	heal_timer := NewTimer(1, true, true)
	health_pad := HealthPad{clump.uuid, rect, heal_amount, heal_timer, time_left}

	append(&spells, health_pad)
	clump.spell_cooldowns[.HEALTH_PAD] = SPELL_COOLDOWN
}

UpdateHealthPad :: proc(pad: ^HealthPad, index: int) {
	UpdateTimer(&pad.heal_timer)
	if pad.heal_timer.ding do for clump in GetAllClumps() {
		if clump.uuid != pad.owner do continue
		if ClumpIntersectsRect(clump^, pad.rect) do HealClump(clump, pad.heal_amount)
	}

	pad.time_left -= rl.GetFrameTime()
	if pad.time_left < 0 && len(spells) > index do unordered_remove(&spells, index)
}

DrawHealthPad :: proc(pad: HealthPad) {
	rl.DrawRectangleRec(pad.rect, rl.GREEN)
}

GetHealthPadStats :: proc(hexagon_type_amounts: [HexagonType]int) -> (time_left: f32, size: f32, heal_amount: f32) {
	time_left = 10 + f32(hexagon_type_amounts[.HEALTH_PAD_UPGRADE_TIME]) * 4
	size = 150 + f32(hexagon_type_amounts[.HEALTH_PAD_UPGRADE_SIZE]) * 100
	heal_amount = 3 + f32(hexagon_type_amounts[.HEALTH_PAD_UPGRADE_HEAL_AMOUNT])
	return time_left, size, heal_amount
}

// ICE BALL

ICE_BALL_SPEED :: 120
ICE_BALL_SIZE :: 50

IceBall :: struct { owner: uuid.Identifier, pos: rl.Vector2, vel: rl.Vector2, put_floor_timer: Timer, time_left: f32, 
	floor_size: f32, freeze_time: f32 }

PlayerThrowIceBall :: proc() {
	vel := VelocityFrom2Points(CameraPos(player), rl.GetMousePosition())
	ThrowIceBall(&player.clump, vel)
}

EnemyThrowIceBall :: proc(enemy: ^Enemy, target: rl.Vector2) {
	rot := RotationFrom2Points(enemy.pos, target)
	inac := GetEnemyInaccuracy(enemy.ai_state)
	rot += rand.float32_range(-inac, inac)
	vel := VelocityFromRotation(rot)
	ThrowIceBall(&enemy.clump, vel)
}

ThrowIceBall :: proc(clump: ^HexagonClump, vel: rl.Vector2) {
	put_floor_timer := NewTimer(1, true, true)

	time_left, floor_size, freeze_time := GetIceBallStats(GetHexagonTypeAmounts(clump^))
	
	append(&spells, IceBall{clump.uuid, clump.pos, vel, put_floor_timer, time_left, floor_size, freeze_time})
	clump.spell_cooldowns[.ICE_BALL] = SPELL_COOLDOWN
}

UpdateIceBall :: proc(ball: ^IceBall, index: int) {
	UpdateTimer(&ball.put_floor_timer)
	if ball.put_floor_timer.ding {
		rect := rl.Rectangle{ball.pos.x - ball.floor_size / 2, ball.pos.y - ball.floor_size / 2, ball.floor_size, ball.floor_size}
		for clump in GetAllClumps() {
			if clump.uuid == ball.owner do continue
			if ClumpIntersectsRect(clump^, rect) do clump.frozen_time_left = ball.freeze_time
		}
	}

	ball.time_left -= rl.GetFrameTime()
	if ball.time_left <= 0 && len(spells) > index do unordered_remove(&spells, index)

	ball.pos += ball.vel * ICE_BALL_SPEED * rl.GetFrameTime()
}

DrawIceBall :: proc(ball: IceBall) {
	rl.DrawCircleV(ball.pos, ICE_BALL_SIZE, rl.SKYBLUE)
}

GetIceBallStats :: proc(hexagon_type_amounts: [HexagonType]int) -> (time_left: f32, floor_size: f32, freeze_time: f32) {
	time_left = 3 + f32(hexagon_type_amounts[.ICE_BALL_UPGRADE_RANGE])
	floor_size = 75 + f32(hexagon_type_amounts[.ICE_BALL_UPGRADE_RANGE]) * 25
	freeze_time = 3 + f32(hexagon_type_amounts[.ICE_BALL_UPGRADE_RANGE])
	return time_left, floor_size, freeze_time
}

// FIREBALL

FIREBALL_SPEED :: 80

Fireball :: struct { owner: uuid.Identifier, pos: rl.Vector2, vel: rl.Vector2, time_left: f32, burn_time: f32, size: f32, damage: f32 }

PlayerThrowFireball :: proc() {
	vel := VelocityFrom2Points(CameraPos(player), rl.GetMousePosition())
	ThrowFireball(&player.clump, vel)
}

EnemyThrowFireball :: proc(enemy: ^Enemy, target: rl.Vector2) {
	rot := RotationFrom2Points(enemy.pos, target)
	inac := GetEnemyInaccuracy(enemy.ai_state)
	rot += rand.float32_range(-inac, inac)
	vel := VelocityFromRotation(rot)
	ThrowFireball(&enemy.clump, vel)
}

ThrowFireball :: proc(clump: ^HexagonClump, vel: rl.Vector2) {
	burn_time, size, damage := GetFireballStats(GetHexagonTypeAmounts(clump^))
	
	append(&spells, Fireball{clump.uuid, clump.pos, vel, 3, burn_time, size, damage})
	clump.spell_cooldowns[.FIREBALL] = SPELL_COOLDOWN
}

UpdateFireball :: proc(ball: ^Fireball, index: int) {
	for clump in GetAllClumps() {
		if clump.uuid == ball.owner do continue
		damage_timer := NewTimer(1, true, true)
		if ClumpIntersectsCircle(clump^, ball.pos, ball.size) do clump.burning = { damage_timer, ball.burn_time, ball.damage }
	}

	ball.time_left -= rl.GetFrameTime()
	if ball.time_left <= 0 && len(spells) > index do unordered_remove(&spells, index)

	ball.pos += ball.vel * FIREBALL_SPEED * rl.GetFrameTime()
}

DrawFireball :: proc(ball: Fireball) {
	rl.DrawCircleV(ball.pos, ball.size, rl.ORANGE)
}

GetFireballStats :: proc(hexagon_type_amounts: [HexagonType]int) -> (burn_time: f32, size: f32, damage: f32) {
	burn_time = 7 + f32(hexagon_type_amounts[.FIREBALL_UPGRADE_TIME])
	size = 30 + f32(hexagon_type_amounts[.FIREBALL_UPGRADE_SIZE]) * 15
	damage = 3 + f32(hexagon_type_amounts[.FIREBALL_UPGRADE_DAMAGE]) / 2
	return burn_time, size, damage
}

// BLACK HOLE

BLACK_HOLE_SPEED :: 4 * 60
BLACK_HOLE_DECELERATION :: 5 * 60

BlackHole :: struct { owner: uuid.Identifier, pos: rl.Vector2, vel: rl.Vector2, time_left: f32, suction_power: f32, size: f32 }

PlayerThrowBlackHole :: proc() {
	vel := VelocityFrom2Points(CameraPos(player), rl.GetMousePosition())
	ThrowBlackHole(&player.clump, vel)
}

EnemyThrowBlackHole :: proc(enemy: ^Enemy, target: rl.Vector2) {
	rot := RotationFrom2Points(enemy.pos, target)
	inac := GetEnemyInaccuracy(enemy.ai_state)
	rot += rand.float32_range(-inac, inac)
	vel := VelocityFromRotation(rot)
	ThrowBlackHole(&enemy.clump, vel)
}

ThrowBlackHole :: proc(clump: ^HexagonClump, vel: rl.Vector2) {
	time_left, suction_power, size := GetBlackHoleStats(GetHexagonTypeAmounts(clump^))
	new_vel := vel * BLACK_HOLE_SPEED
	
	append(&spells, BlackHole{clump.uuid, clump.pos, new_vel, time_left, suction_power, size})
	clump.spell_cooldowns[.BLACK_HOLE] = SPELL_COOLDOWN
}

UpdateBlackHole :: proc(hole: ^BlackHole, index: int) {
	Accelerate(&hole.vel.x, 0, BLACK_HOLE_DECELERATION)
	Accelerate(&hole.vel.y, 0, BLACK_HOLE_DECELERATION)
	
	for clump in GetAllClumps() {
		if clump.uuid == hole.owner do continue
		if rl.Vector2Distance(hole.pos, clump.pos) > hole.size * 10 do continue
		target_vel := VelocityFrom2Points(clump.pos, hole.pos) * 60
		Accelerate(&clump.vel.x, target_vel.x, hole.suction_power)
		Accelerate(&clump.vel.y, target_vel.y, hole.suction_power)
		if ClumpIntersectsCircle(clump^, hole.pos, hole.size) do clump.vel = 0
	}

	hole.time_left -= rl.GetFrameTime()
	if hole.time_left <= 0 && len(spells) > index do unordered_remove(&spells, index)
	
	hole.pos += hole.vel * rl.GetFrameTime()
}

DrawBlackHole :: proc(hole: BlackHole) {
	rl.DrawCircleV(hole.pos, hole.size, rl.PURPLE)
}

GetBlackHoleStats :: proc(hexagon_type_amounts: [HexagonType]int) -> (time_left: f32, suction_power: f32, size: f32) {
	time_left = 5 + f32(hexagon_type_amounts[.BLACK_HOLE_UPGRADE_TIME])
	suction_power = (5 + f32(hexagon_type_amounts[.BLACK_HOLE_UPGRADE_SUCTION_POWER])) * 60
	size = 20 + f32(hexagon_type_amounts[.BLACK_HOLE_UPGRADE_SIZE]) * 5
	return time_left, suction_power, size
}