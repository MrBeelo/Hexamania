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
	enemy_spawn_timer = NewTimer(12, true, true)
}

UpdateEnemies :: proc() { 
	for &enemy, index in enemies do UpdateEnemy(&enemy, index)

	// Spawning Enemies
	UpdateTimer(&enemy_spawn_timer)
	if enemy_spawn_timer.ding {
		if player.camera.zoom == 0 do return // Will cause a division by zero error, but this shouldn't happen anyway.
		HEXAGON_DEVELOPEMENT_FACTOR :: 25 // The bigger this is, the less hexagons enemies will have (based on time)
		
		hexagons := math.floor_div(int(GetElapsedStopwatchTime(time_survived)), HEXAGON_DEVELOPEMENT_FACTOR) + 1
		hexagons = rand.int_range(hexagons, hexagons + 3)
		if hexagons <= 0 do return
		
		hexagon_types := make([]HexagonType, hexagons)
		for i in 0..<hexagons do hexagon_types[i] = .RIFLE // NOTE: It's obvious.
		
		pos := GetRandomSpawnPos()
		rot := RotationFrom2Points(pos, player.camera.target)
		rot += rand.float32_range(-10, 10)
		vel := VelocityFromRotation(rot)
		
		append(&enemies, NewEnemy(hexagon_types, pos, vel))
		enemy_spawn_timer.duration = rand.float32_range(10, 15)
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
	if enemy.health <= 20 { SetAIState(enemy, .PANIC); return }
	if enemy.attacker != nil && enemy.ai_state != .PANIC { SetAIState(enemy, .AGGRO); return }
	SetAIState(enemy, .INSPECT)
}

SetAIState :: proc(enemy: ^Enemy, state: AIState) {
	if enemy.ai_state != state do enemy.turn_timer.start_time = f32(rl.GetTime()) - enemy.turn_timer.duration
	if enemy.ai_state != state do enemy.attack_timer.start_time = f32(rl.GetTime()) - enemy.attack_timer.duration
	enemy.ai_state = state
}

GetEnemyInaccuracy :: proc(state: AIState) -> f32 {
	switch state {
	case .ROAM,.INSPECT: return 15
	case .AGGRO: return 10
	case .PANIC: return 25
	}
	
	return 0
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

// AI Helpers

EnemyAttack :: proc(enemy: ^Enemy, target: rl.Vector2, spell_chance: f32, spell_weights: [SpellType]int) {
	should_use_rifle := true
	num := rand.float32_range(0, 100)
	if spell_chance > num do should_use_rifle = false

	if should_use_rifle {
		EnemyFirePellet(enemy, target)
	} else {
		if !EnemyDoRandomSpell(enemy, target, spell_weights) do EnemyFirePellet(enemy, target)
	}
}

EnemyDoRandomSpell :: proc(enemy: ^Enemy, target: rl.Vector2, spell_weights: [SpellType]int) -> bool {
	sum := spell_weights[.HEALTH_PAD] + spell_weights[.ICE_BALL] + spell_weights[.FIREBALL]
	if sum <= 0 do return false
	num := rand.int_range(0, sum)

	preferred: SpellType
	switch {
	case num < spell_weights[.HEALTH_PAD]: preferred = .HEALTH_PAD
	case num < spell_weights[.HEALTH_PAD] + spell_weights[.ICE_BALL]: preferred = .ICE_BALL
	case: preferred = .FIREBALL
	}

	spell_order: [len(SpellType)]SpellType
	switch preferred {
	case .HEALTH_PAD: spell_order = {.HEALTH_PAD, .ICE_BALL, .FIREBALL}
	case .ICE_BALL: spell_order = {.ICE_BALL, .FIREBALL, .HEALTH_PAD}
	case .FIREBALL: spell_order = {.FIREBALL, .HEALTH_PAD, .ICE_BALL}
	}

	for spell in spell_order {
		if spell_weights[spell] == 0 do continue
		if enemy.spell_cooldowns[spell] > 0 do continue
		if !HasSpell(enemy.clump, spell) do continue
		
		switch spell {
		case .HEALTH_PAD: SummonHealthPad(&enemy.clump)
		case .ICE_BALL: EnemyThrowIceBall(enemy, target)
		case .FIREBALL: EnemyThrowFireball(enemy, target)
		}
		return true
	}
	
	return false
}

// AI States

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
		enemy.attack_timer.duration = rand.float32_range(7, 12)
		spell_weights := [SpellType]int{.HEALTH_PAD = 0, .ICE_BALL = 1, .FIREBALL = 1}
		EnemyAttack(enemy, target.pos, 10, spell_weights)
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
		enemy.attack_timer.duration = GetRifleDelay(enemy.clump) * rand.float32_range(3, 3.5)
		spell_weights := [SpellType]int{.HEALTH_PAD = 0, .ICE_BALL = 1, .FIREBALL = 1}
		EnemyAttack(enemy, target.pos, 25, spell_weights)
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
		enemy.attack_timer.duration = GetRifleDelay(enemy.clump) * rand.float32_range(4, 4.5)
		spell_weights := [SpellType]int{.HEALTH_PAD = 1, .ICE_BALL = 0, .FIREBALL = 0}
		EnemyAttack(enemy, attacker.pos, 50, spell_weights)
	}
}