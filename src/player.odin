package main

import rl "vendor:raylib"
import "core:math"
import "core:math/rand"

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
	camera := rl.Camera2D{screen_size / 2, 0, 0, 1}
	return Player{ NewHexagonClump({.RIFLE, .HEALTH_PAD, .ICE_BALL, .FIREBALL, .BLACK_HOLE}, 0), camera, {}, false, nil }
}

GetMaxPlayerVelocity :: proc(plr: Player) -> f32 {
	max_speed := GetPlayerSpeed(plr)
	if player.spr.sprinting do max_speed *= 1.5
	return max_speed
}

UpdatePlayer :: proc(plr: ^Player) {
	// Manage death
	if plr.dead_time > 0.5 {
		StopStopwatch(&time_survived)
		game_state = .FINISH
	}
	
	// Manage speed
	speed := GetPlayerSpeed(plr^)
	if Holding(.HORIZ) && Holding(.VERT) do speed *= (1 / 1.41)
	
	// Movement
	if Holding(.UP) {
	 	Accelerate(&plr.vel.y, -speed, PLAYER_ACCELERATION)
	} else if Holding(.DOWN) {
		Accelerate(&plr.vel.y, speed, PLAYER_ACCELERATION)
	} else do Accelerate(&plr.vel.y, 0, PLAYER_ACCELERATION)
	
	if Holding(.LEFT) {
	 	Accelerate(&plr.vel.x, -speed, PLAYER_ACCELERATION)
	} else if Holding(.RIGHT) {
	 	Accelerate(&plr.vel.x, speed, PLAYER_ACCELERATION)
	} else do Accelerate(&plr.vel.x, 0, PLAYER_ACCELERATION)

	// Clamp velocities down to 0 if they are low and player isn't moving
	if !Holding(.HORIZ) && !Holding(.VERT) {
		DEADZONE :: f32(3)
		if math.abs(plr.vel.x) < DEADZONE do plr.vel.x = 0
		if math.abs(plr.vel.y) < DEADZONE do plr.vel.y = 0
	}

	plr.spr.sprinting = Holding(.SPRINT) && plr.spr.sprint_secs > 0

	// Clamp player velocity for safety
	max_vel := GetMaxPlayerVelocity(plr^)
	plr.vel.x = clamp(plr.vel.x, -max_vel, max_vel)
	plr.vel.y = clamp(plr.vel.y, -max_vel, max_vel)

	// Camera Management
	HandlePlayerCamera(plr)

	// Update the powerups the player has
	UpdateBoundPowerups(&plr.bound_powerups)

	if rl.IsMouseButtonPressed(.RIGHT) {
		if plr.active_spell == nil {
			for spell in SpellType do if HasSpell(plr.clump, spell) { plr.active_spell = spell; plr.spell_mode = true }
		} else {
			plr.spell_mode = !plr.spell_mode
		}
	}

	if !plr.spell_mode {
		if rl.IsMouseButtonPressed(.LEFT) && plr.rifle_delay <= 0 do PlayerFirePellet()
	} else {
		move := rl.GetMouseWheelMove()
		if move > 0 do ChangePlayerActiveSpell(true, plr.active_spell.?, plr.active_spell.?)
		if move < 0 do ChangePlayerActiveSpell(false, plr.active_spell.?, plr.active_spell.?)

		if rl.IsMouseButtonPressed(.LEFT) && player.spell_cooldowns[player.active_spell.?] <= 0 {
			switch plr.active_spell {
			case .HEALTH_PAD: SummonHealthPad(&plr.clump)
			case .ICE_BALL: PlayerThrowIceBall()
			case .FIREBALL: PlayerThrowFireball()
			case .BLACK_HOLE: PlayerThrowBlackHole()
			}
			plr.spell_mode = false
		}
	}	

	UpdateHexagonClump(&plr.clump)
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

DrawPlayer :: proc(plr: ^Player) {
	DrawHexagonClump(plr.clump)
	DrawPlayerFace()
	if debug_on do DrawDebugText(plr.pos, "%.0f hp, %s", plr.health, ShortUUID(plr.uuid))
}

GetPlayerSpeed :: proc(plr: Player) -> f32 {
	speed := f32(BASE_PLAYER_SPEED)
	if plr.bound_powerups[.SPEED].time_remaining > 0 do speed *= plr.bound_powerups[.SPEED].value
	return speed
}

HandlePlayerCamera :: proc(plr: ^Player) {	
	for i in 0..=1 {
		diff := plr.pos[i] - plr.camera.target[i]
		threshold := screen_size[i] / 10 / plr.camera.zoom

		if diff > threshold do plr.camera.target[i] = plr.pos[i] - threshold
		if diff < -threshold do plr.camera.target[i] = plr.pos[i] + threshold
	}

	target_zoom := GetCameraZoom(GetPlayerLevel(plr^))
	if plr.camera.zoom < target_zoom do plr.camera.zoom += rl.GetFrameTime()
	if plr.camera.zoom > target_zoom do plr.camera.zoom -= rl.GetFrameTime()
}

CameraPos :: proc(plr: Player) -> rl.Vector2 {
	return (plr.pos - plr.camera.target) * plr.camera.zoom + plr.camera.offset
}

GetCameraZoom :: proc(level: int) -> f32 {
	switch level {
	case 1: return 1.1
	case 2: return 0.9
	case 3: return 0.8
	case 4: return 0.7
	}

	return 1
}

GetPlayerLevel :: proc(plr: Player) -> int { return GetLevel(plr.hexagon_types) }

GetLevel :: proc(hexagon_types: []HexagonType) -> int {
	hexagons := len(hexagon_types)
	switch {
	case hexagons < 1 + 6: return 1
	case hexagons < 1 + 6 + 12: return 2
	case hexagons < 1 + 6 + 12 + 18: return 3
	case hexagons == 1 + 6 + 12 + 18: return 4
	}

	return 1
}

// For spawning enemies and powerups
GetRandomSpawnPos :: proc(range: f32 = 120) -> rl.Vector2 {
	visible_screen_size := screen_size / player.camera.zoom
	min_dist := visible_screen_size / 2
	max_dist := min_dist + range

	pos_x, pos_y: f32
	x_free := bool(rand.int_range(0, 2))
	if x_free {
		pos_x = rand.float32_range(-max_dist.x, max_dist.x)
		pos_y = RangeRand({min_dist.y, max_dist.y})
	} else {
		pos_x = RangeRand({min_dist.x, max_dist.x})
		pos_y = rand.float32_range(-max_dist.y, max_dist.y)
	}
	
	pos := player.camera.target + {pos_x, pos_y}
	return pos
}

GetWorldCameraRect :: proc(cam := player.camera) -> rl.Rectangle {
	size := screen_size * cam.zoom
	pos := cam.target - size / 2
	return {pos.x, pos.y, size.x, size.y}
}