package main

import rl "vendor:raylib"
import "core:encoding/uuid"

spells: [dynamic]Spell
Spell :: union {
	HealthPad,
	IceBall,
	Fireball,
}

UpdateSpells :: proc() {
	for &spell, index in spells do switch &s in spell {
	case HealthPad: UpdateHealthPad(&s, index)
	case IceBall: UpdateIceBall(&s, index)
	case Fireball: UpdateFireball(&s, index)
	}
}

DrawSpellsBelow :: proc() {
	for spell in spells do switch s in spell {
	case HealthPad: DrawHealthPad(s)
	case IceBall: DrawIceBall(s)
	case Fireball: DrawFireball(s)
	}
}

// HEALTH PAD

HealthPad :: struct { owner: uuid.Identifier, rect: rl.Rectangle, heal_amount: f32, heal_timer: Timer, time_left: f32 }

SummonHealthPad :: proc(clump: HexagonClump) {
	hexagon_type_amounts := GetHexagonTypeAmounts(clump)
	time_left := 10 + f32(hexagon_type_amounts[.HEALTH_PAD_UPGRADE_TIME]) * 5
	size := 150 + f32(hexagon_type_amounts[.HEALTH_PAD_UPGRADE_SIZE]) * 50
	heal_amount := 3 + f32(hexagon_type_amounts[.HEALTH_PAD_UPGRADE_HEAL_AMOUNT])

	rect := rl.Rectangle{clump.pos.x - size / 2, clump.pos.y - size / 2, size, size}
	heal_timer := NewTimer(2, true, true)
	health_pad := HealthPad{clump.uuid, rect, heal_amount, heal_timer, time_left}

	append(&spells, health_pad)
}

UpdateHealthPad :: proc(pad: ^HealthPad, index: int) {
	UpdateTimer(&pad.heal_timer)
	if pad.heal_timer.ding do for clump in GetAllClumps() {
		if clump.uuid != pad.owner do continue
		if ClumpIntersectsRect(clump^, pad.rect) do clump.health += pad.heal_amount
	}

	pad.time_left -= rl.GetFrameTime()
	if pad.time_left < 0 && len(spells) > index do unordered_remove(&spells, index)
}

DrawHealthPad :: proc(pad: HealthPad) {
	rl.DrawRectangleLinesEx(pad.rect, 5, rl.GREEN)
}

// ICE BALL

ICE_BALL_SPEED :: 120

IceBall :: struct { owner: uuid.Identifier, pos: rl.Vector2, vel: rl.Vector2, put_floor_timer: Timer, time_left: f32, 
	floor_size: f32, freeze_time: f32 }

PlayerThrowIceBall :: proc() {
	vel := VelocityFrom2Points(CameraPos(player), rl.GetMousePosition())
	put_floor_timer := NewTimer(1, true, true)

	hexagon_type_amounts := GetHexagonTypeAmounts(player.clump)
	time_left := 3 + f32(hexagon_type_amounts[.ICE_BALL_UPGRADE_RANGE])
	floor_size := 75 + f32(hexagon_type_amounts[.ICE_BALL_UPGRADE_RANGE]) * 25
	freeze_time := 3 + f32(hexagon_type_amounts[.ICE_BALL_UPGRADE_RANGE])
	
	append(&spells, IceBall{player.uuid, player.pos, vel, put_floor_timer, time_left, floor_size, freeze_time})
}

EnemyThrowIceBall :: proc() {
	// NOTE: To add tomorrow
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
	rl.DrawCircleLinesV(ball.pos, 50, rl.SKYBLUE)
}

// FIREBALL

FIREBALL_SPEED :: 80

Fireball :: struct { owner: uuid.Identifier, pos: rl.Vector2, vel: rl.Vector2, time_left: f32, burn_time: f32, size: f32, damage: f32 }

PlayerThrowFireball :: proc() {
	vel := VelocityFrom2Points(CameraPos(player), rl.GetMousePosition())

	hexagon_type_amounts := GetHexagonTypeAmounts(player.clump)
	burn_time := 7 + f32(hexagon_type_amounts[.FIREBALL_UPGRADE_TIME])
	size := 30 + f32(hexagon_type_amounts[.FIREBALL_UPGRADE_SIZE]) * 15
	damage := 3 + f32(hexagon_type_amounts[.FIREBALL_UPGRADE_DAMAGE]) / 2
	
	append(&spells, Fireball{player.uuid, player.pos, vel, 3, burn_time, size, damage})
}

EnemyThrowFireball :: proc() {
	// NOTE: To add tomorrow
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
	rl.DrawCircleLinesV(ball.pos, ball.size, rl.ORANGE)
}