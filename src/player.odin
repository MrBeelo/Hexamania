package main

import rl "raylib"
import "core:math"

BASE_PLAYER_SPEED :: 3 * 60
PLAYER_ACCELERATION :: 8 * 60

Player :: struct {
	using clump: HexagonClump,
	camera: rl.Camera2D,
	bound_powerups: [PowerupType]BoundPowerup,
	spell_mode: bool,
	active_spell: Maybe(SpellType),
}

NewPlayer :: proc() -> Player {
	camera := rl.Camera2D{SCREEN_SIZE / 2, 0, 0, 1}
	return Player{ NewHexagonClump({.RIFLE, .RIFLE}, 0), camera, {}, false, nil }
}

UpdatePlayer :: proc(plr: ^Player) {
	// Manage death
	if plr.dead_time > 0.5 do StartDeathSequence()
	
	// Manage speed
	speed := GetPlayerSpeed(plr^)
	if Holding(.HORIZ) && Holding(.VERT) do speed *= (1 / 1.41)

	target_speed_modifier_x := int(Holding(.RIGHT)) - int(Holding(.LEFT))
	target_speed_modifier_y := int(Holding(.DOWN)) - int(Holding(.UP))

	Accelerate(&plr.vel.x, speed * f32(target_speed_modifier_x), PLAYER_ACCELERATION)
	Accelerate(&plr.vel.y, speed * f32(target_speed_modifier_y), PLAYER_ACCELERATION)

	if !has_moved && (Holding(.HORIZ) || Holding(.VERT)) do has_moved = true

	// Clamp velocities down to 0 if they are low and player isn't moving
	if !Holding(.HORIZ) && !Holding(.VERT) {
		DEADZONE :: f32(10)
		if math.abs(plr.vel.x) < DEADZONE do plr.vel.x = 0
		if math.abs(plr.vel.y) < DEADZONE do plr.vel.y = 0
	}

	plr.sprinting = Holding(.SPRINT) && plr.sprint_secs > 0
	if Holding(.SPRINT) do has_sprinted = true

	// Clamp player velocity for safety
	max_vel := GetMaxPlayerVelocity(plr^)
	plr.vel.x = clamp(plr.vel.x, -max_vel, max_vel)
	plr.vel.y = clamp(plr.vel.y, -max_vel, max_vel)

	// Camera Management
	HandlePlayerCamera(plr)

	// Update the powerups the player has
	UpdateBoundPowerups(&plr.bound_powerups)

	if rl.IsMouseButtonPressed(.RIGHT) {
		has_opened_spell_menu = true
		if plr.active_spell == nil {
			for spell in SpellType do if HasSpell(plr.clump, spell) { plr.active_spell = spell; plr.spell_mode = true }
		} else {
			plr.spell_mode = !plr.spell_mode
		}
	}

	if !plr.spell_mode {
		if rl.IsMouseButtonPressed(.LEFT) && plr.rifle_delay <= 0 && player.can_shoot {
			has_shot = true
			PlayerFirePellet()
		}
	} else {
		move := rl.GetMouseWheelMove()
		if move > 0 do ChangePlayerActiveSpell(true, plr.active_spell.?, plr.active_spell.?)
		if move < 0 do ChangePlayerActiveSpell(false, plr.active_spell.?, plr.active_spell.?)

		if rl.IsMouseButtonPressed(.LEFT) && player.spell_cooldowns[player.active_spell.?] <= 0 {
			has_used_spell = true
			switch plr.active_spell {
			case .HEALTH_PAD: SummonHealthPad(&plr.clump)
			case .ICE_BALL: PlayerThrowIceBall()
			case .FIREBALL: PlayerThrowFireball()
			case .BLACK_HOLE: PlayerThrowBlackHole()
			}
			plr.spell_mode = false

			rl.SetSoundVolume(fire_spell, 1)
			rl.PlaySound(fire_spell)
		}
	}	

	UpdateHexagonClump(&plr.clump)
}

DrawPlayer :: proc(plr: ^Player) {
	DrawHexagonClump(plr.clump)
	DrawPlayerFace()
	if debug_on do DrawDebugText(plr.pos, "%.0f hp, %s", plr.health, ShortUUID(plr.uuid))
}

ChangePlayerActiveSpell :: proc(up: bool, start_spell: SpellType, test_spell: SpellType) {
	index := int(test_spell)
	index += 1 if up else -1
	index %= len(SpellType)
	if index < 0 do index += len(SpellType)

	new_spell := SpellType(index)
	if new_spell == start_spell do return
	if HasSpell(player.clump, new_spell) { player.active_spell = new_spell; return }
	ChangePlayerActiveSpell(up, start_spell, new_spell)
}

GetPlayerSpeed :: proc(plr: Player) -> f32 {
	speed := f32(BASE_PLAYER_SPEED)
	if plr.bound_powerups[.SPEED].time_remaining > 0 do speed *= plr.bound_powerups[.SPEED].value
	return speed
}

GetMaxPlayerVelocity :: proc(plr: Player) -> f32 {
	max_speed := GetPlayerSpeed(plr)
	if player.sprinting do max_speed *= 1.5
	return max_speed
}