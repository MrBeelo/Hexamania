package main

import rl "vendor:raylib"
import "core:math"
import "core:math/rand"

BASE_PLAYER_SPEED :: 3 * 60
PLAYER_ACCELERATION :: 5 * 60

Player :: struct {
	using clump: HexagonClump,
	camera: rl.Camera2D,
	bound_powerups: [PowerupType]BoundPowerup,
	spell_mode: bool,
	active_spell: Maybe(SpellType),
}

NewPlayer :: proc() -> Player {
	camera := rl.Camera2D{screen_size / 2, 0, 0, 1}
	return Player{ NewHexagonClump({.RIFLE, .BLACK_HOLE}, 0), camera, {}, false, nil }
}

UpdatePlayer :: proc(plr: ^Player) {
	// Manage death
	if plr.health <= 0 {
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
	if debug_on do DrawDebugText(plr.pos, "%.0f hp, %s", plr.health, ShortUUID(plr.uuid))
}

DrawPlayerHealthBar :: proc() {
	bar_size := rl.Vector2{screen_size.x / 2, 32}
	
	shell_pos := rl.Vector2{screen_size.x / 2 - bar_size.x / 2, screen_size.y - bar_size.y}
	rl.DrawRectangleV(shell_pos, bar_size, rl.BLACK)

	BUFFER :: f32(3)
	health_bar_size := bar_size - {BUFFER * 2, BUFFER}
	health_bar_size.x = health_bar_size.x * player.health / MAX_HEALTH
	rl.DrawRectangleV(shell_pos + BUFFER, health_bar_size, rl.RED)

	sprint_bar_size := bar_size - {BUFFER * 2, BUFFER}
	sprint_bar_size.x = sprint_bar_size.x * player.spr.sprint_secs / MAX_SPRINT_SECS
	rl.DrawRectangleV(shell_pos + BUFFER + {0, bar_size.y * 2 / 3}, sprint_bar_size, rl.SKYBLUE)
}

DrawSpellMenu :: proc() {
	if !player.spell_mode do return

	texture: rl.Texture2D
	switch player.active_spell.? {
	case .HEALTH_PAD: texture = hexagon_textures[.HEALTH_PAD]
	case .ICE_BALL: texture = hexagon_textures[.ICE_BALL]
	case .FIREBALL: texture = hexagon_textures[.FIREBALL]
	case .BLACK_HOLE: texture = hexagon_textures[.BLACK_HOLE]
	}

	cooldown := int(math.ceil(player.spell_cooldowns[player.active_spell.?]))
	cooldown_text := string(rl.TextFormat("%d", cooldown))
	BOX_SIZE :: f32(96)
	BUFFER :: f32(15)

	src := rl.Rectangle{0, 0, f32(texture.width), f32(texture.height)}
	dest := rl.Rectangle{screen_size.x - BOX_SIZE / 2 - BUFFER, BUFFER + BOX_SIZE / 2, BOX_SIZE, BOX_SIZE}
	rot := math.mod_f32(f32(rl.GetTime()), 360) * 15
	
	rl.DrawTexturePro(texture, src, dest, BOX_SIZE / 2, rot, rl.WHITE if cooldown <= 0 else rl.GRAY)
	if cooldown > 0 do DrawTextCenter(cooldown_text, {screen_size.x - (BUFFER + BOX_SIZE / 2), BUFFER + BOX_SIZE / 2}, 32, .QUICKSAND_MEDIUM)
}

DrawActiveSpellPreview :: proc() {
	if !player.spell_mode do return
	hexagon_type_amounts := GetHexagonTypeAmounts(player.clump)
	if player.spell_cooldowns[player.active_spell.?] > 0 do return // If the active spell is on cooldown, don't draw the preview
	switch player.active_spell.? {
	case .HEALTH_PAD: {
		_, size, _ := GetHealthPadStats(hexagon_type_amounts)
		size *= player.camera.zoom
		pos := CameraPos(player)
		rect := rl.Rectangle{pos.x - size / 2, pos.y - size / 2, size, size}
		rl.DrawRectangleLinesEx(rect, 5, rl.GREEN)
	}
	case .ICE_BALL: {
		size := ICE_BALL_SIZE * player.camera.zoom
		rl.DrawCircleLinesV(rl.GetMousePosition(), size, rl.SKYBLUE)
	}
	case .FIREBALL: {
		_, size, _ := GetFireballStats(hexagon_type_amounts)
		size *= player.camera.zoom
		rl.DrawCircleLinesV(rl.GetMousePosition(), size, rl.ORANGE)
	}
	case .BLACK_HOLE: {
		_, _, size := GetBlackHoleStats(hexagon_type_amounts)
		size *= player.camera.zoom
		rl.DrawCircleLinesV(rl.GetMousePosition(), size, rl.PURPLE)
	}
	}
}

GetPlayerSpeed :: proc(plr: Player) -> f32 {
	speed := f32(BASE_PLAYER_SPEED)
	if plr.bound_powerups[.SPEED].time_remaining > 0 do speed *= plr.bound_powerups[.SPEED].value
	return speed
}

HandlePlayerCamera :: proc(plr: ^Player) {	
	for i in 0..=1 {
		diff := plr.pos[i] - plr.camera.target[i]
		threshold := screen_size[i] / 5 / plr.camera.zoom

		if diff > threshold do plr.camera.target[i] = plr.pos[i] - threshold
		if diff < -threshold do plr.camera.target[i] = plr.pos[i] + threshold
	}

	plr.camera.zoom = GetCameraZoom(GetPlayerLevel(plr^))
}

CameraPos :: proc(plr: Player) -> rl.Vector2 {
	return (plr.pos - plr.camera.target) * plr.camera.zoom + plr.camera.offset
}

GetCameraZoom :: proc(level: int) -> f32 {
	switch level {
	case 1: return 1.2
	case 2: return 1.1
	case 3: return 0.9
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