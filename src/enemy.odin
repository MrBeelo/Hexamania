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
AIState :: enum { ROAM, INSPECT, AGGRO, PANIC }

Enemy :: struct {
	using clump: HexagonClump,
	ai_state: AIState,
	switch_timer: Timer,
	fire_timer: Timer,
}

NewEnemy :: proc(hexagon_types: []HexagonType, pos: rl.Vector2, health := MAX_HEALTH) -> Enemy {
	rot := rand.float32_range(-180, 180)
	clump := NewHexagonClump(hexagon_types, pos, {}, rot, health)
	
	switch_timer := NewTimer(2, true, true, true)
	fire_timer := NewTimer(10, true, true)
	
	return Enemy{clump, .INSPECT, switch_timer, fire_timer}
}

UpdateEnemies :: proc() { for &enemy, index in enemies do UpdateEnemy(&enemy, index) }

UpdateEnemy :: proc(enemy: ^Enemy, index: int) {
	#partial switch enemy.ai_state {
	case .ROAM: HandleRoamingState(enemy)
	case .INSPECT: HandleInspectState(enemy, &player.clump) // NOTE: Replace player.clump with closest clump.
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

HandleRoamingState :: proc(enemy: ^Enemy) {
	UpdateTimer(&enemy.switch_timer)
	if enemy.switch_timer.ding {
		enemy.switch_timer.duration = rand.float32_range(2, 10)

		enemy.vel.x = RangeRand({40, 60})
		enemy.vel.y = RangeRand({40, 60})
	}
}

HandleInspectState :: proc(enemy: ^Enemy, target: ^HexagonClump) {
	UpdateTimer(&enemy.switch_timer)
	UpdateTimer(&enemy.fire_timer)

	if enemy.switch_timer.ding {
		enemy.switch_timer.duration = rand.float32_range(2, 3)
		rot := RotationFrom2Points(enemy.pos, target.pos) + RangeRand({20, 40})
		enemy.vel = VelocityFromRotation(rot) * rand.float32_range(40, 60)
	}

	if enemy.fire_timer.ding {
		enemy.fire_timer.duration = rand.float32_range(5, 12)
		EnemyFirePellet(enemy^, target.pos)
	}
}