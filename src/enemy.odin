package main

import rl "vendor:raylib"
import "core:math/rand"

ENEMY_WANDER_VEL_RANGE :: rl.Vector2{40, 60}
enemies: [dynamic]Enemy

// AI State is the way each entity's AI behaves
// Each state is activated when a certain condition is met
// WANDER: No enemies are nearby, just roaming around
// INSPECT: Activates when an enemy is a certain distance from it,
//          Tries to attack with light attacks, and not frequently.
// AGGRO: Activates when the enemy is hit by an attack, above a 
//        certain amount of health. Enemy tries its best to fight
//        the enemy/enemies. Will pay the most attention to the enemy
//        with the least health.
// RUN: Activates when in AGGRO and the enemy is below the set amount
//      of health. Enemy runs away from attacking enemy/enemies.
AIState :: enum { WANDER, INSPECT, AGGRO, RUN }

Enemy :: struct {
	using clump: HexagonClump,
	ai_state: AIState,
	wander_switch_timer: Timer,
}

NewEnemy :: proc(hexagon_types: []HexagonType, pos: rl.Vector2, health := MAX_HEALTH) -> Enemy {
	rot := rand.float32_range(-180, 180)
	clump := NewHexagonClump(hexagon_types, pos, {}, rot, health)
	
	wander_switch_timer := NewTimer(2, true, true)
	wander_switch_timer.start_time = f32(rl.GetTime()) - wander_switch_timer.duration
	
	return Enemy{clump, .WANDER, wander_switch_timer}
}

UpdateEnemies :: proc() { for &enemy, index in enemies do UpdateEnemy(&enemy, index) }

UpdateEnemy :: proc(enemy: ^Enemy, index: int) {
	#partial switch enemy.ai_state {
	case .WANDER: HandleWanderState(enemy)
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
	
	text := rl.TextFormat("%.0f hp, %v, %d%d%d%d", enemy.health, enemy.ai_state, enemy.uuid[8], enemy.uuid[9], enemy.uuid[10], enemy.uuid[11])
	text_size := f32(rl.MeasureText(text, 16))
	text_pos := enemy.pos - {text_size / 2, 50}
	rl.DrawTextEx(rl.GetFontDefault(), text, text_pos, 16, 2, rl.RED)
}

HandleWanderState :: proc(enemy: ^Enemy) {
	UpdateTimer(&enemy.wander_switch_timer)
	if enemy.wander_switch_timer.ding {
		enemy.wander_switch_timer.duration = rand.float32_range(2, 10)

		diff := ENEMY_WANDER_VEL_RANGE.y - ENEMY_WANDER_VEL_RANGE.x
		enemy.vel.x = rand.float32_range(-diff, diff)
		enemy.vel.y = rand.float32_range(-diff, diff)
		enemy.vel.x += ENEMY_WANDER_VEL_RANGE.x if enemy.vel.x >= 0 else -ENEMY_WANDER_VEL_RANGE.x
		enemy.vel.y += ENEMY_WANDER_VEL_RANGE.x if enemy.vel.y >= 0 else -ENEMY_WANDER_VEL_RANGE.x
		
	}
}