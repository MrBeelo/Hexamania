package main

import rl "vendor:raylib"
import "core:encoding/uuid"
import "core:math"
import "core:math/rand"

SpellType :: enum { HEALTH_PAD, ICE_BALL, FIREBALL, BLACK_HOLE }
spell_textures: [enum{HEALTH, ICE, FIRE1, FIRE2, FIRE3, HOLE, CIRCLE_OVERLAY}]rl.Texture2D

spells: [dynamic]Spell
Spell :: union {
	HealthPad,
	IceBall,
	Fireball,
	BlackHole,
}

LoadSpells :: proc() {
	spell_textures = {
		.HEALTH = rl.LoadTexture("res/spell/health_pad_texture.png"),
		.ICE = rl.LoadTexture("res/spell/ice_ball_texture.png"),
		.FIRE1 = rl.LoadTexture("res/spell/fireball_texture1.png"),
		.FIRE2 = rl.LoadTexture("res/spell/fireball_texture2.png"),
		.FIRE3 = rl.LoadTexture("res/spell/fireball_texture3.png"),
		.HOLE = rl.LoadTexture("res/spell/black_hole_texture.png"),
		.CIRCLE_OVERLAY = rl.LoadTexture("res/spell/circle_overlay.png"),
	}

	for texture in spell_textures do rl.SetTextureFilter(texture, .BILINEAR)
}

UnloadSpells :: proc() {
	for spell in spell_textures do rl.UnloadTexture(spell)
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

HealthPad :: struct { owner: uuid.Identifier, pos: rl.Vector2, size: f32, max_size: f32, heal_amount: f32, heal_timer: Timer, time_left: f32, rot: f32 }

SummonHealthPad :: proc(clump: ^HexagonClump) {
	time_left, size, heal_amount := GetHealthPadStats(GetHexagonTypeAmounts(clump^))

	//rect := rl.Rectangle{clump.pos.x - size / 2, clump.pos.y - size / 2, size, size}
	heal_timer := NewTimer(1, true, true)
	rot := f32(rand.int_range(0, 4)) * 90
	health_pad := HealthPad{clump.uuid, clump.pos, size, size, heal_amount, heal_timer, time_left, rot}

	append(&spells, health_pad)
	clump.spell_cooldowns[.HEALTH_PAD] = SPELL_COOLDOWN
}

UpdateHealthPad :: proc(pad: ^HealthPad, index: int) {
	if pad.time_left <= 0.3 do pad.size = pad.max_size * (pad.time_left / 0.3)
	
	UpdateTimer(&pad.heal_timer)
	if pad.heal_timer.ding do for clump in hexagon_clumps {
		if clump.uuid != pad.owner do continue
		rect := rl.Rectangle{pad.pos.x - pad.size / 2, pad.pos.y - pad.size / 2, pad.size, pad.size}
		if ClumpIntersectsRect(clump^, rect) do HealClump(clump, pad.heal_amount)
	}

	pad.time_left -= rl.GetFrameTime()
	if pad.time_left < 0 && len(spells) > index do unordered_remove(&spells, index)
}

DrawHealthPad :: proc(pad: HealthPad) {
	src := rl.Rectangle{0, 0, f32(spell_textures[.HEALTH].width), f32(spell_textures[.HEALTH].height)}
	color := rl.Color{255, 255, 255, 100} if pad.owner != player.uuid else rl.WHITE
	rect := rl.Rectangle{pad.pos.x, pad.pos.y, pad.size, pad.size}
	rl.DrawTexturePro(spell_textures[.HEALTH], src, rect, pad.size / 2, pad.rot, color)
}

GetHealthPadStats :: proc(hexagon_type_amounts: [HexagonType]int) -> (time_left: f32, size: f32, heal_amount: f32) {
	time_left = 10 + f32(hexagon_type_amounts[.HEALTH_PAD_UPGRADE_TIME]) * 2
	size = 150 + f32(hexagon_type_amounts[.HEALTH_PAD_UPGRADE_SIZE]) * 33
	heal_amount = 3 + f32(hexagon_type_amounts[.HEALTH_PAD_UPGRADE_HEAL_AMOUNT]) * 2 / 3
	return time_left, size, heal_amount
}

// ICE BALL

ICE_BALL_SPEED :: 400
ICE_BALL_SIZE :: 40

IceBall :: struct { owner: uuid.Identifier, pos: rl.Vector2, vel: rl.Vector2, time_left: f32, 
	size: f32, freeze_time: f32 }

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
	time_left, floor_size, freeze_time := GetIceBallStats(GetHexagonTypeAmounts(clump^))
	
	append(&spells, IceBall{clump.uuid, clump.pos, vel, time_left, floor_size, freeze_time})
	clump.spell_cooldowns[.ICE_BALL] = SPELL_COOLDOWN
}

UpdateIceBall :: proc(ball: ^IceBall, index: int) {
	for clump in hexagon_clumps {
		if clump.uuid == ball.owner do continue
		if ClumpIntersectsCircle(clump^, ball.pos, ball.size) do clump.frozen_time_left = ball.freeze_time
	}

	ball.time_left -= rl.GetFrameTime()
	if ball.time_left <= 0 && len(spells) > index do unordered_remove(&spells, index)

	ball.pos += ball.vel * ICE_BALL_SPEED * rl.GetFrameTime()
}

DrawIceBall :: proc(ball: IceBall) {
	texture := spell_textures[.ICE]
	src := rl.Rectangle{0, 0, f32(texture.width), f32(texture.height)}
	dest := rl.Rectangle{ball.pos.x, ball.pos.y, ICE_BALL_SIZE, ICE_BALL_SIZE}
	color := rl.WHITE
	rot := math.mod_f32(f32(rl.GetTime() * 100), 360)
	rl.DrawTexturePro(texture, src, dest, ICE_BALL_SIZE / 2, rot, color)
}

GetIceBallStats :: proc(hexagon_type_amounts: [HexagonType]int) -> (time_left: f32, size: f32, freeze_time: f32) {
	time_left = 3 + f32(hexagon_type_amounts[.ICE_BALL_UPGRADE_RANGE])
	size = 15 + f32(hexagon_type_amounts[.ICE_BALL_UPGRADE_RANGE]) * 4
	freeze_time = 3 + f32(hexagon_type_amounts[.ICE_BALL_UPGRADE_RANGE])
	return time_left, size, freeze_time
}

// FIREBALL

FIREBALL_SPEED :: 400

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
	exploded := false
	exploded_clump_uuid: uuid.Identifier
	damage_timer := NewTimer(1, true, true)
	
	for clump in hexagon_clumps {
		if clump.uuid == ball.owner do continue
		if ClumpIntersectsCircle(clump^, ball.pos, ball.size) { 
			if len(spells) > index do unordered_remove(&spells, index)
			DamageClumpNoAttacker(clump, 65)
			clump.burning = { damage_timer, ball.burn_time, ball.damage }
			exploded = true
			exploded_clump_uuid = clump.uuid
			rl.PlaySound(explosion)
		}
	}

	if exploded do for nearby_clump in hexagon_clumps {
		if nearby_clump.uuid == exploded_clump_uuid || nearby_clump.uuid == ball.owner do return
		if ClumpIntersectsCircle(nearby_clump^, ball.pos, ball.size * 3) { 
			nearby_clump.burning = { damage_timer, ball.burn_time, ball.damage }
		}
	}

	ball.time_left -= rl.GetFrameTime()
	if ball.time_left <= 0 && len(spells) > index do unordered_remove(&spells, index)

	ball.pos += ball.vel * FIREBALL_SPEED * rl.GetFrameTime()
}

DrawFireball :: proc(ball: Fireball) {
	for i in 0..=2 {
		texture: rl.Texture2D
		switch i {
		case 0: texture = spell_textures[.FIRE1]
		case 1: texture = spell_textures[.FIRE2]
		case 2: texture = spell_textures[.FIRE3]
		}

		src := rl.Rectangle{0, 0, f32(texture.width), f32(texture.height)}
		dest := rl.Rectangle{ball.pos.x, ball.pos.y, ball.size, ball.size}
		color := GetBurningOverlayColor(f32(i) / 3)
		rot := math.mod_f32(f32(rl.GetTime() * 100), 360)
		rl.DrawTexturePro(texture, src, dest, ball.size / 2, rot, color)
	}	
}

GetFireballStats :: proc(hexagon_type_amounts: [HexagonType]int) -> (burn_time: f32, size: f32, damage: f32) {
	burn_time = 7 + f32(hexagon_type_amounts[.FIREBALL_UPGRADE_TIME])
	size = 30 + f32(hexagon_type_amounts[.FIREBALL_UPGRADE_SIZE]) * 10
	damage = 3 + f32(hexagon_type_amounts[.FIREBALL_UPGRADE_DAMAGE]) / 2
	return burn_time, size, damage
}

// BLACK HOLE

BLACK_HOLE_SPEED :: 6 * 60
BLACK_HOLE_DECELERATION :: 5 * 60

BlackHole :: struct { owner: uuid.Identifier, pos: rl.Vector2, vel: rl.Vector2, time_left: f32, suction_power: f32, size: f32, max_size: f32 }

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
	
	append(&spells, BlackHole{clump.uuid, clump.pos, new_vel, time_left, suction_power, size, size})
	clump.spell_cooldowns[.BLACK_HOLE] = SPELL_COOLDOWN
}

UpdateBlackHole :: proc(hole: ^BlackHole, index: int) {
	Accelerate(&hole.vel.x, 0, BLACK_HOLE_DECELERATION)
	Accelerate(&hole.vel.y, 0, BLACK_HOLE_DECELERATION)
	
	for clump in hexagon_clumps {
		if clump.uuid == hole.owner do continue
		if rl.Vector2Distance(hole.pos, clump.pos) > hole.size * 25 do continue
		target_vel := VelocityFrom2Points(clump.pos, hole.pos) * 60
		Accelerate(&clump.vel.x, target_vel.x, hole.suction_power)
		Accelerate(&clump.vel.y, target_vel.y, hole.suction_power)
		if ClumpIntersectsCircle(clump^, hole.pos, hole.size / 3) do clump.vel = 0
		if rl.Vector2Distance(clump.pos, hole.pos) - hole.size - (f32(GetLevel(clump.hexagon_types)) - 1) * HEXAGON_SIZE < 100 do clump.can_shoot = false
	}

	hole.time_left -= rl.GetFrameTime()
	if hole.time_left <= 0 && len(spells) > index do unordered_remove(&spells, index)

	if hole.time_left <= 1 do hole.size = hole.max_size * hole.time_left
	
	hole.pos += hole.vel * rl.GetFrameTime()
}

DrawBlackHole :: proc(hole: BlackHole) {
	src := rl.Rectangle{0, 0, f32(spell_textures[.HOLE].width), f32(spell_textures[.HOLE].height)}
	
	DELAY :: 2
	time := f32(rl.GetTime())
	time = math.mod_f32(time, DELAY)
	factor := math.sin(rl.PI * time / DELAY)
	color := rl.ColorLerp(rl.Color{14, 0, 49, 255}, rl.Color{20, 0, 71, 255}, factor)
	if hole.owner == player.uuid do color.a = 200
	
	dest := rl.Rectangle{hole.pos.x, hole.pos.y, hole.size, hole.size}

	rl.DrawTexturePro(spell_textures[.HOLE], src, dest, hole.size / 2, 0, color)
}

GetBlackHoleStats :: proc(hexagon_type_amounts: [HexagonType]int) -> (time_left: f32, suction_power: f32, size: f32) {
	time_left = 5 + f32(hexagon_type_amounts[.BLACK_HOLE_UPGRADE_TIME])
	suction_power = (6 + f32(hexagon_type_amounts[.BLACK_HOLE_UPGRADE_SUCTION_POWER]) * 3 / 2) * 60
	size = 60 + f32(hexagon_type_amounts[.BLACK_HOLE_UPGRADE_SIZE]) * 10
	return time_left, suction_power, size
}