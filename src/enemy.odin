package main

import rl "vendor:raylib"
import "core:math/rand"

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
}

NewEnemy :: proc(hexagon_types: []HexagonType, pos: rl.Vector2, health := MAX_HEALTH) -> Enemy {
	rot := rand.float32_range(-180, 180)
	clump := NewHexagonClump(hexagon_types, pos, {}, rot, health)
	
	switch_timer := NewTimer(2, true, true, true)
	fire_timer := NewTimer(5, true, true)
	
	return Enemy{clump, .ROAM, switch_timer, fire_timer}
}

UpdateEnemies :: proc() { for &enemy, index in enemies do UpdateEnemy(&enemy, index) }

UpdateEnemy :: proc(enemy: ^Enemy, index: int) {
	switch enemy.ai_state {
	case .ROAM: HandleRoamingState(enemy)
	case .INSPECT: HandleInspectState(enemy, &player.clump) // NOTE: Replace player.clump with closest clump.
	case .AGGRO: HandleAggroState(enemy, &player.clump) // NOTE: Replace player.clump with the clump that attacked last.
	case .PANIC: HandlePanicState(enemy, &player.clump) // NOTE: Same as AGGRO.
	}
	
	if enemy.health <= 0 {
		points += len(enemy.clump.hexagon_types)
		ThrowRandomHeart(enemy.pos)
		unordered_remove(&enemies, index)
	}
	
	UpdateHexagonClump(&enemy.clump)
}

DrawEnemies :: proc() { for enemy in enemies do DrawEnemy(enemy) }

DrawEnemy :: proc(enemy: Enemy) {
	DrawHexagonClump(enemy.clump)
	DrawDebugText(enemy.pos, "%.0f hp, %v, %d%d%d%d", enemy.health, enemy.ai_state, enemy.uuid[8], enemy.uuid[9], enemy.uuid[10], enemy.uuid[11])
}

// NOTE: HUGE NOTE
// NOTE: ALL of the values used here (for speed and such) should be
// NOTE: changed based on the *hexagons of the clump*

HandleRoamingState :: proc(enemy: ^Enemy) {
	UpdateTimer(&enemy.turn_timer)
	if enemy.turn_timer.ding {
		enemy.turn_timer.duration = rand.float32_range(2, 10)

		// Choose random velocity to use
		enemy.vel.x = RangeRand({20, 60})
		enemy.vel.y = RangeRand({20, 60})
	}
}

HandleInspectState :: proc(enemy: ^Enemy, target: ^HexagonClump) {
	UpdateTimer(&enemy.turn_timer)
	UpdateTimer(&enemy.attack_timer)

	// Move towards the target, but not completely (like to the side)
	if enemy.turn_timer.ding {
		enemy.turn_timer.duration = rand.float32_range(2, 3)
		rot := RotationFrom2Points(enemy.pos, target.pos) + RangeRand({30, 50})
		enemy.vel = VelocityFromRotation(rot) * rand.float32_range(40, 60)
	}

	// Fire, but not too frequently, see if target responds
	if enemy.attack_timer.ding {
		enemy.attack_timer.duration = rand.float32_range(5, 12)
		EnemyFirePellet(enemy^, target.pos)
	}
}

HandleAggroState :: proc(enemy: ^Enemy, target: ^HexagonClump) {
	UpdateTimer(&enemy.turn_timer)
	UpdateTimer(&enemy.attack_timer)

	// Move towards the target
	if enemy.turn_timer.ding {
		enemy.turn_timer.duration = rand.float32_range(1, 2)
		rot := RotationFrom2Points(enemy.pos, target.pos) + RangeRand({10, 20})
		enemy.vel = VelocityFromRotation(rot) * rand.float32_range(60, 70)
	}

	// Sprint to catch up to target
	if rl.Vector2Distance(enemy.pos, target.pos) > 300 && enemy.spr.sprint_secs > 0 {
		enemy.spr.sprinting = true
	}

	// Fire as fast as possible
	if enemy.attack_timer.ding {
		enemy.attack_timer.duration = rand.float32_range(2, 3)
		EnemyFirePellet(enemy^, target.pos)
	}
}

HandlePanicState :: proc(enemy: ^Enemy, attacker: ^HexagonClump) {
	UpdateTimer(&enemy.turn_timer)
	UpdateTimer(&enemy.attack_timer)

	// Move away from the target
	if enemy.turn_timer.ding {
		enemy.turn_timer.duration = rand.float32_range(1, 2)
		rot := RotationFrom2Points(enemy.pos, attacker.pos) + RangeRand({10, 20}) + 180 // We add 180 so that direction flips
		enemy.vel = VelocityFromRotation(rot) * rand.float32_range(60, 70)
	}

	// Sprint if it can
	if enemy.spr.sprint_secs > 0 {
		enemy.spr.sprinting = true
	}

	// Fire as much as it can, while running away
	if enemy.attack_timer.ding {
		enemy.attack_timer.duration = rand.float32_range(4, 6)
		EnemyFirePellet(enemy^, attacker.pos)
	}
}