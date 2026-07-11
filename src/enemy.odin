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
		
		hexagons := math.floor_div(int(GetElapsedStopwatchTime(time_survived)), HEXAGON_DEVELOPEMENT_FACTOR) + 2
		hexagons = rand.int_range(hexagons, hexagons + 3)
		if hexagons <= 0 do return
		hexagons = math.min(hexagons, MAX_HEXAGONS)
		
		hexagon_types := make([]HexagonType, hexagons)
		GenEnemyHexagonTypes(&hexagon_types)
		
		pos := GetRandomSpawnPos()
		rot := RotationFrom2Points(pos, player.camera.target)
		rot += rand.float32_range(-10, 10)
		vel := VelocityFromRotation(rot)
		
		append(&enemies, NewEnemy(hexagon_types, pos, vel))
		enemy_spawn_timer.duration = rand.float32_range(10, 15)
	}
}

GenEnemyHexagonTypes :: proc(hexagon_types: ^[]HexagonType) {
	length := len(hexagon_types)
	
	main_type := rand.choice_enum(SpellType)
	secondary_type_num := int(main_type) + 1
	secondary_type_num %= len(SpellType)
	secondary_type := SpellType(secondary_type_num)

	main_type_added, secondary_type_added: bool

	// Middle hex is always a rifle
	hexagon_types[0] = .RIFLE

	// Main type is guaranteed to appear on the first shell, somewhere
	main_type_index := rand.int_range(1, 5)
	// Same for the secondary type, but for the second shell
	secondary_type_index := rand.int_range(7, 19)
	
	for i in 1..<MAX_HEXAGONS {
		if i >= length do return
		add_main_type := i == main_type_index
		add_secondary_type := i == secondary_type_index
		
		if add_main_type {
			// Add the main type
			hexagon_types[i] = GetHexagonTypeFromSpellType(main_type)
			main_type_added = true
		} else if add_secondary_type {
			// Add the secondary type
			hexagon_types[i] = GetHexagonTypeFromSpellType(secondary_type)
			secondary_type_added = true
		} else {
			// Add a random upgrade, based on the spell types the entity has
			upgrade_type_to_add := rand.int_range(0, 3) // nil, main, secondary
			upgrade_to_add := rand.int_range(0, 3) // All spell types have 3 upgrades

			if upgrade_type_to_add == 2 && !secondary_type_added do upgrade_type_to_add = 1
			if upgrade_type_to_add == 1 && !main_type_added do upgrade_type_to_add = 0

			upgrades: [3]HexagonType
			switch upgrade_type_to_add {
			case 0: upgrades = GetHexagonUpgradesFromSpellType(nil)
			case 1: upgrades = GetHexagonUpgradesFromSpellType(main_type)
			case 2: upgrades = GetHexagonUpgradesFromSpellType(secondary_type)
			}

			hexagon_types[i] = upgrades[upgrade_to_add]
		}
	}
}

GetHexagonTypeFromSpellType :: proc(spell: SpellType) -> HexagonType {
	switch spell {
	case .HEALTH_PAD: return .HEALTH_PAD
	case .ICE_BALL: return .ICE_BALL
	case .FIREBALL: return .FIREBALL
	case .BLACK_HOLE: return .BLACK_HOLE
	}
	return .RIFLE
}

// nil corresponds to RIFLE
GetHexagonUpgradesFromSpellType :: proc(spell: Maybe(SpellType)) -> [3]HexagonType {
	if spell == nil do return {.RIFLE_UPGRADE_FIRE_RATE, .RIFLE_UPGRADE_PELLET_SPEED, .RIFLE_UPGRADE_DAMAGE}
	switch spell.? {
	case .HEALTH_PAD: return {.HEALTH_PAD_UPGRADE_HEAL_AMOUNT, .HEALTH_PAD_UPGRADE_SIZE, .HEALTH_PAD_UPGRADE_TIME}
	case .ICE_BALL: return {.ICE_BALL_UPGRADE_RANGE, .ICE_BALL_UPGRADE_FLOOR_SIZE, .ICE_BALL_UPGRADE_FREEZE_TIME}
	case .FIREBALL: return {.FIREBALL_UPGRADE_SIZE, .FIREBALL_UPGRADE_TIME, .FIREBALL_UPGRADE_DAMAGE}
	case .BLACK_HOLE: return {.BLACK_HOLE_UPGRADE_SUCTION_POWER, .BLACK_HOLE_UPGRADE_SIZE, .BLACK_HOLE_UPGRADE_TIME}
	}

	return {.RIFLE, .RIFLE, .RIFLE}
}

UpdateEnemy :: proc(enemy: ^Enemy, index: int) {
	RANGE :: 350
	is_clump_close, closest_clump := GetClosestClump(enemy, RANGE)
	ManageAIState(enemy, is_clump_close, closest_clump)
	
	if enemy.dead_time <= 0 do switch enemy.ai_state {
	case .ROAM: HandleRoamingState(enemy)
	case .INSPECT: { assert(closest_clump != nil); HandleInspectState(enemy, closest_clump) }
	case .AGGRO: { assert(enemy.attacker != nil); HandleAggroState(enemy, enemy.attacker) }
	case .PANIC: { assert(closest_clump != nil); HandlePanicState(enemy, closest_clump) }
	}
	
	if enemy.dead_time > 0.5 {
		hexagon_type := GetHexagonTypeToThrow(enemy^)
		if hexagon_type == nil do ThrowRandomWorldPowerup(enemy.pos); else do ThrowHeart(enemy.pos, hexagon_type.?)
		
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

GetHexagonTypeToThrow :: proc(enemy: Enemy) -> Maybe(HexagonType) {
	if GetPlayerLevel(player) == MAX_LEVEL do return nil
	shuffled := Shuffle(enemy.hexagon_types)
	
	for hexagon_type in shuffled {
		if hexagon_type == .RIFLE do continue
		if hexagon_type == .HEALTH_PAD do if HasSpell(player.clump, .HEALTH_PAD) do continue; else do return hexagon_type
		if hexagon_type == .ICE_BALL do if HasSpell(player.clump, .ICE_BALL) do continue; else do return hexagon_type
		if hexagon_type == .FIREBALL do if HasSpell(player.clump, .FIREBALL) do continue; else do return hexagon_type
		if hexagon_type == .BLACK_HOLE do if HasSpell(player.clump, .BLACK_HOLE) do continue; else do return hexagon_type

		// From now on, it's guaranteed that the hexagon is an upgrade
		spell := GetSpellFromHexagonType(hexagon_type)
		if spell == nil || (spell != nil && HasSpell(player.clump, spell.?)) {
			hexagon_amounts := GetHexagonTypeAmounts(player.clump)
			if hexagon_amounts[hexagon_type] > 3 do continue
			return hexagon_type
		}
	}

	return nil
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
	DrawEnemyFace(enemy)
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
	sum := spell_weights[.HEALTH_PAD] + spell_weights[.ICE_BALL] + spell_weights[.FIREBALL] + spell_weights[.BLACK_HOLE]
	if sum <= 0 do return false
	num := rand.int_range(0, sum)

	preferred: SpellType
	switch {
	case num < spell_weights[.HEALTH_PAD]: preferred = .HEALTH_PAD
	case num < spell_weights[.HEALTH_PAD] + spell_weights[.ICE_BALL]: preferred = .ICE_BALL
	case num < spell_weights[.HEALTH_PAD] + spell_weights[.ICE_BALL] + spell_weights[.FIREBALL]: preferred = .FIREBALL
	case: preferred = .BLACK_HOLE
	}

	spell_order: [len(SpellType)]SpellType
	switch preferred {
	case .HEALTH_PAD: spell_order = {.HEALTH_PAD, .ICE_BALL, .FIREBALL, .BLACK_HOLE}
	case .ICE_BALL: spell_order = {.ICE_BALL, .FIREBALL, .BLACK_HOLE, .HEALTH_PAD}
	case .FIREBALL: spell_order = {.FIREBALL, .BLACK_HOLE, .HEALTH_PAD, .ICE_BALL}
	case .BLACK_HOLE: spell_order = {.BLACK_HOLE, .HEALTH_PAD, .ICE_BALL, .FIREBALL}
	}

	for spell in spell_order {
		if spell_weights[spell] == 0 do continue
		if enemy.spell_cooldowns[spell] > 0 do continue
		if !HasSpell(enemy.clump, spell) do continue
		
		switch spell {
		case .HEALTH_PAD: SummonHealthPad(&enemy.clump)
		case .ICE_BALL: EnemyThrowIceBall(enemy, target)
		case .FIREBALL: EnemyThrowFireball(enemy, target)
		case .BLACK_HOLE: EnemyThrowBlackHole(enemy, target)
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
		spell_weights := [SpellType]int{.HEALTH_PAD = 0, .ICE_BALL = 1, .FIREBALL = 1, .BLACK_HOLE = 0}
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
		_, _, fire_rate := GetRifleStats(GetHexagonTypeAmounts(enemy.clump))
		enemy.attack_timer.duration = fire_rate * rand.float32_range(3, 3.5)
		spell_weights := [SpellType]int{.HEALTH_PAD = 0, .ICE_BALL = 2, .FIREBALL = 2, .BLACK_HOLE = 1}
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
		_, _, fire_rate := GetRifleStats(GetHexagonTypeAmounts(enemy.clump))
		enemy.attack_timer.duration = fire_rate * rand.float32_range(4, 4.5)
		spell_weights := [SpellType]int{.HEALTH_PAD = 3, .ICE_BALL = 0, .FIREBALL = 0, .BLACK_HOLE = 1}
		EnemyAttack(enemy, attacker.pos, 50, spell_weights)
	}
}