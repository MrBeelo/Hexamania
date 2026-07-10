package main

import rl "vendor:raylib"
import "core:math"
import "core:math/rand"

ENEMY_ACCELERATION :: 3 * 60

enemy_spawn_timer: Timer
enemies: [dynamic]Enemy

// AI State is the way each entity's AI behaves
// Each state is activated when a certain condition is met
// ROAM: No enemies are nearby, just roaming around
// INSPECT: Activates when an enemy is a certain distance from it,
//          Tries to attack with light attacks, and not frequently.
// AGGRO: Activates when the enemy is hit by an attack, above a 
//        certain amount of health. Enemy tries its best to fight
//        the enemy/enemies. Will pay the most attention to the enemy
//        with the least health.
// PANIC: Activates when in AGGRO and the enemy is below the set amount
//      of health. Enemy runs away from attacking enemy/enemies.
// Each enemy has two timers for their AI:
// turn_timer: When the enemy should switch direction
// attack_timer: When the enemy should attack
AIState :: enum { ROAM, INSPECT, AGGRO, PANIC }

Enemy :: struct {
	using clump: HexagonClump,
	ai_state: AIState,
	turn_timer: Timer,
	attack_timer: Timer,
	target_vel: rl.Vector2,
	time_away_from_player: f32,
}

NewEnemy :: proc(hexagon_types: []HexagonType, pos: rl.Vector2, vel := rl.Vector2{}, health := MAX_HEALTH) -> Enemy {
	rot := rand.float32_range(-180, 180)
	clump := NewHexagonClump(hexagon_types, pos, vel, rot, health)
	
	switch_timer := NewTimer(2, true, true, true)
	fire_timer := NewTimer(5, true, true)
	
	return Enemy{clump, .ROAM, switch_timer, fire_timer, 0, 0}
}

InitEnemies :: proc() {
	enemy_spawn_timer = NewTimer(5, true, true)
}

UpdateEnemies :: proc() { 
	for &enemy, index in enemies do UpdateEnemy(&enemy, index)

	// Spawning Enemies
	UpdateTimer(&enemy_spawn_timer)
	if enemy_spawn_timer.ding {
		if player.camera.zoom == 0 do return // Will cause a division by zero error, but this shouldn't happen anyway.
		
		hexagons := math.floor_div(int(GetElapsedStopwatchTime(time_survived)), 15) + 1
		hexagons = rand.int_range(hexagons, hexagons + 3)
		if hexagons <= 0 do return
		
		hexagon_types := make([]HexagonType, hexagons)
		for i in 0..<hexagons do hexagon_types[i] = .RIFLE // NOTE: It's obvious.
		
		level := GetLevel(hexagon_types)
		visible_screen_size := screen_size / player.camera.zoom
		min_dist := player.camera.target + visible_screen_size / 2 + (f32(level) - 1) * HEXAGON_SIZE
		pos_x := RangeRand({min_dist.x, min_dist.x + 70})
		pos_y := RangeRand({min_dist.y, min_dist.y + 70})
		pos := rl.Vector2{pos_x, pos_y}

		rot := RotationFrom2Points(pos, player.camera.target)
		rot += rand.float32_range(-10, 10)
		vel := VelocityFromRotation(rot)
		
		append(&enemies, NewEnemy(hexagon_types, pos, vel))
		
		enemy_spawn_timer.duration = rand.float32_range(3, 9)
	}
}

UpdateEnemy :: proc(enemy: ^Enemy, index: int) {
	RANGE :: 350
	is_clump_close, closest_clump := GetClosestClump(enemy, RANGE)
	ManageAIState(enemy, is_clump_close, closest_clump)
	
	switch enemy.ai_state {
	case .ROAM: HandleRoamingState(enemy)
	case .INSPECT: { assert(closest_clump != nil); HandleInspectState(enemy, closest_clump) }
	case .AGGRO: { assert(enemy.attacker != nil); HandleAggroState(enemy, enemy.attacker) }
	case .PANIC: { assert(closest_clump != nil); HandlePanicState(enemy, closest_clump) }
	}
	
	if enemy.health <= 0 {
		if GetPlayerLevel(player) == MAX_LEVEL do ThrowRandomWorldPowerup(enemy.pos); else {
			ThrowRandomHeart(enemy.pos)
			// NOTE: Do type stuff here to throw correct hexaheart
		}
		
		if len(enemies) > index do unordered_remove(&enemies, index)
	}

	Accelerate(&enemy.vel.x, enemy.target_vel.x, ENEMY_ACCELERATION)
	Accelerate(&enemy.vel.y, enemy.target_vel.y, ENEMY_ACCELERATION)

	// Despawn if away from player
	player_dist := rl.Vector2Distance(enemy.pos, player.pos)
	player_dist -= f32(GetPlayerLevel(player) - 1) * HEXAGON_SIZE
	player_dist -= f32(GetLevel(enemy.hexagon_types) - 1) * HEXAGON_SIZE
	if player_dist > 500 do enemy.time_away_from_player += rl.GetFrameTime(); else do enemy.time_away_from_player = 0
	if enemy.time_away_from_player > 20 && len(enemies) > index do unordered_remove(&enemies, index)
	
	UpdateHexagonClump(&enemy.clump)
}

ManageAIState :: proc(enemy: ^Enemy, is_clump_close: bool, closest_clump: ^HexagonClump) {
	if !is_clump_close { SetAIState(enemy, .ROAM); return }
	if enemy.health <= 30 { SetAIState(enemy, .PANIC); return }
	if enemy.attacker != nil && enemy.ai_state != .PANIC { SetAIState(enemy, .AGGRO); return }
	SetAIState(enemy, .INSPECT)
}

SetAIState :: proc(enemy: ^Enemy, state: AIState) {
	if enemy.ai_state != state do enemy.turn_timer.start_time = f32(rl.GetTime()) - enemy.turn_timer.duration
	if enemy.ai_state != state do enemy.attack_timer.start_time = f32(rl.GetTime()) - enemy.attack_timer.duration
	enemy.ai_state = state
}

GetClosestClump :: proc(enemy: ^Enemy, range: f32) -> (found: bool, clump: ^HexagonClump) {
	closest_dist := range
	closest_clump: ^HexagonClump = nil
	
	level := f32(GetLevel(enemy.hexagon_types))
	for other_clump in GetAllClumps() {
		if enemy.uuid == other_clump.uuid do continue
		other_level := f32(GetLevel(other_clump.hexagon_types))
		dist := rl.Vector2Distance(enemy.pos, other_clump.pos) - HEXAGON_SIZE * (level + other_level - 2)
		if dist >= range do continue
		if dist < closest_dist {
			closest_dist = dist
			closest_clump = other_clump
		}
	}

	return closest_dist < range, closest_clump
}

DrawEnemies :: proc() { for enemy in enemies do DrawEnemy(enemy) }

DrawEnemy :: proc(enemy: Enemy) {
	DrawHexagonClump(enemy.clump)
	if debug_on do DrawDebugText(enemy.pos, "%.0f hp, %v, %s", enemy.health, enemy.ai_state, ShortUUID(enemy.uuid))
}

GetDetectionRange :: proc(hexagon_types: []HexagonType) -> f32 {
	return HEXAGON_SIZE * f32(GetLevel(hexagon_types)) * 2 + 300
}

// NOTE: HUGE NOTE
// NOTE: ALL of the values used here (for speed and such) should be
// NOTE: changed based on the *hexagons of the clump*

HandleRoamingState :: proc(enemy: ^Enemy) {
	UpdateTimer(&enemy.turn_timer)
	if enemy.turn_timer.ding {
		enemy.turn_timer.duration = rand.float32_range(2, 10)

		// Choose random velocity to use
		enemy.target_vel.x = RangeRand({20, 60})
		enemy.target_vel.y = RangeRand({20, 60})
	}
}

HandleInspectState :: proc(enemy: ^Enemy, target: ^HexagonClump) {
	UpdateTimer(&enemy.turn_timer)
	UpdateTimer(&enemy.attack_timer)

	// Move towards the target, but not completely (like to the side)
	if enemy.turn_timer.ding {
		enemy.turn_timer.duration = rand.float32_range(2, 3)
		rot := RotationFrom2Points(enemy.pos, target.pos) + RangeRand({30, 50})
		enemy.target_vel = VelocityFromRotation(rot) * rand.float32_range(40, 60)
	}

	// Fire, but not too frequently, see if target responds
	if enemy.attack_timer.ding {
		enemy.attack_timer.duration = rand.float32_range(5, 12)
		EnemyFirePellet(enemy, target.pos)
	}
}

HandleAggroState :: proc(enemy: ^Enemy, target: ^HexagonClump) {
	UpdateTimer(&enemy.turn_timer)
	UpdateTimer(&enemy.attack_timer)

	// Move towards the target
	if enemy.turn_timer.ding {
		enemy.turn_timer.duration = rand.float32_range(1, 2)
		dist := rl.Vector2Distance(enemy.pos, target.pos)

		rot_modifier: f32
		switch {
		case dist < 100: rot_modifier = 150
		case dist < 200: rot_modifier = 60
		}
		
		rot := RotationFrom2Points(enemy.pos, target.pos) + RangeRand({10, 20}) + rot_modifier
		enemy.target_vel = VelocityFromRotation(rot) * rand.float32_range(60, 70)
	}

	// Sprint to catch up to target
	if rl.Vector2Distance(enemy.pos, target.pos) > 300 && enemy.spr.sprint_secs > 0 {
		enemy.spr.sprinting = true
	}

	// Fire as fast as possible
	if enemy.attack_timer.ding {
		enemy.attack_timer.duration = GetRifleDelay(enemy.clump) * rand.float32_range(1.25, 1.75)
		EnemyFirePellet(enemy, target.pos)
	}
}

HandlePanicState :: proc(enemy: ^Enemy, attacker: ^HexagonClump) {
	UpdateTimer(&enemy.turn_timer)
	UpdateTimer(&enemy.attack_timer)

	// Move away from the target
	if enemy.turn_timer.ding {
		enemy.turn_timer.duration = rand.float32_range(0.5, 1)
		rot := RotationFrom2Points(enemy.pos, attacker.pos) + RangeRand({10, 20}) + 180 // We add 180 so that direction flips
		enemy.target_vel = VelocityFromRotation(rot) * rand.float32_range(60, 70)
	}

	// Sprint if it can
	if enemy.spr.sprint_secs > 0 {
		enemy.spr.sprinting = true
	}

	// Fire as much as it can, while running away
	if enemy.attack_timer.ding {
		enemy.attack_timer.duration = GetRifleDelay(enemy.clump) * rand.float32_range(2, 2.5)
		EnemyFirePellet(enemy, attacker.pos)
	}
}