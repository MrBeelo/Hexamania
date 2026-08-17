package main

import rl "raylib"
import "core:math"
import "core:math/rand"
import "core:slice"

ENEMY_ACCELERATION :: 8 * 60

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
AI_State :: enum { ROAM, INSPECT, AGGRO, PANIC }

Enemy :: struct {
	using clump: Hexagon_Clump,
	ai_state: AI_State,
	turn_timer: Timer,
	attack_timer: Timer,
	target_vel: rl.Vector2,
	time_away_from_player: f32,
}

new_enemy :: proc(hexagon_types: []Hexagon_Type, pos: rl.Vector2, vel := rl.Vector2{}) -> Enemy {
	rot := rand.float32_range(-180, 180)
	clump := new_clump(hexagon_types, pos, vel, rot)
	
	switch_timer := new_timer(2, true, true, true)
	fire_timer := new_timer(5, true, true)
	
	return Enemy{clump, .ROAM, switch_timer, fire_timer, 0, 0}
}

init_enemies :: proc() {
	enemy_spawn_timer = new_timer(12, true, true)
}

update_enemies :: proc() { 
	for &enemy, index in enemies do update_enemy(&enemy, index)

	// Spawning Enemies
	update_timer(&enemy_spawn_timer)
	if enemy_spawn_timer.ding do spawn_enemy()
}

spawn_enemy :: proc() {
	if player.camera.zoom == 0 do return // Will cause a division by zero error, but this shouldn't happen anyway.
	HEXAGON_DEVELOPEMENT_FACTOR :: 25 // The bigger this is, the less hexagons enemies will have (based on time)
	
	hexagons := math.floor_div(int(get_elapsed_stopwatch_time(time_survived)), HEXAGON_DEVELOPEMENT_FACTOR) + 2
	hexagons = rand.int_range(hexagons, hexagons + 3)
	if hexagons <= 0 do return
	hexagons = math.min(hexagons, MAX_HEXAGONS)
	
	hexagon_types := make([]Hexagon_Type, hexagons)
	get_enemy_hexagon_types(&hexagon_types)
	
	pos := get_random_spawn_pos()
	rot := rotation_from_points(pos, player.camera.target)
	rot += rand.float32_range(-10, 10)
	vel := velocity_from_rotation(rot)
	
	append(&enemies, new_enemy(hexagon_types, pos, vel))
	enemy_spawn_timer.duration = rand.float32_range(7, 12)
	delete(hexagon_types)
}

@(private = "file")
get_max_enemy_velocity :: proc(enemy: Enemy) -> f32 {
	max_speed := f32(70)
	if player.sprinting do max_speed *= 1.5
	return max_speed
}

get_enemy_hexagon_types :: proc(hexagon_types: ^[]Hexagon_Type) {
	length := len(hexagon_types)
	
	main_type := rand.choice_enum(Spell_Type)
	secondary_type_num := int(main_type) + 1
	secondary_type_num %= len(Spell_Type)
	secondary_type := Spell_Type(secondary_type_num)

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
			hexagon_types[i] = spell_to_hexagon(main_type)
			main_type_added = true
		} else if add_secondary_type {
			// Add the secondary type
			hexagon_types[i] = spell_to_hexagon(secondary_type)
			secondary_type_added = true
		} else {
			// Add a random upgrade, based on the spell types the entity has
			upgrade_type_to_add := rand.int_range(0, 3) // nil, main, secondary
			upgrade_to_add := rand.int_range(0, 3) // All spell types have 3 upgrades

			if upgrade_type_to_add == 2 && !secondary_type_added do upgrade_type_to_add = 1
			if upgrade_type_to_add == 1 && !main_type_added do upgrade_type_to_add = 0

			upgrades: [3]Hexagon_Type
			switch upgrade_type_to_add {
			case 0: upgrades = spell_to_upgrades(nil)
			case 1: upgrades = spell_to_upgrades(main_type)
			case 2: upgrades = spell_to_upgrades(secondary_type)
			}

			hexagon_types[i] = upgrades[upgrade_to_add]
		}
	}
}

update_enemy :: proc(enemy: ^Enemy, index: int) {
	RANGE :: 350
	is_clump_close, closest_clump := get_closest_clump_to_enemy(enemy, RANGE)
	manage_ai_state(enemy, is_clump_close, closest_clump)
	
	if enemy.dead_time <= 0 do switch enemy.ai_state {
	case .ROAM: handle_roaming_state(enemy)
	case .INSPECT: { assert(closest_clump != nil); handle_inspect_state(enemy, closest_clump) }
	case .AGGRO: { assert(enemy.attacker != nil); handle_aggro_state(enemy, enemy.attacker) }
	case .PANIC: { assert(closest_clump != nil); handle_panic_state(enemy, closest_clump) }
	}
	
	if enemy.dead_time > 0.5 {
		hexagon_type := get_hexagon_type_to_throw(enemy^)
		if hexagon_type == nil do throw_random_world_powerup(enemy.pos); else do throw_heart(enemy.pos, hexagon_type.?)

		destroy_clump(enemy.clump)
		if len(enemies) > index do unordered_remove(&enemies, index)
		player_action_list.killed_enemy = true
	}

	// For safety :)
	max_velocity := get_max_enemy_velocity(enemy^)
	enemy.vel.x = clamp(enemy.vel.x, -max_velocity, max_velocity)
	enemy.vel.y = clamp(enemy.vel.y, -max_velocity, max_velocity)

	accelerate(&enemy.vel.x, enemy.target_vel.x, ENEMY_ACCELERATION)
	accelerate(&enemy.vel.y, enemy.target_vel.y, ENEMY_ACCELERATION)

	// Despawn if away from player
	player_dist := rl.Vector2Distance(enemy.pos, player.pos)
	player_dist -= f32(get_level(player.hexagon_types) - 1) * HEXAGON_SIZE
	player_dist -= f32(get_level(enemy.hexagon_types) - 1) * HEXAGON_SIZE
	if player_dist > 500 do enemy.time_away_from_player += rl.GetFrameTime(); else do enemy.time_away_from_player = 0
	if enemy.time_away_from_player > 20 && len(enemies) > index do unordered_remove(&enemies, index)
	
	update_clump(&enemy.clump)
}

get_hexagon_type_to_throw :: proc(enemy: Enemy) -> Maybe(Hexagon_Type) {
	if get_level(player.hexagon_types) == MAX_LEVEL do return nil

	for spell in Spell_Type {
		hexagon_type := spell_to_hexagon(spell)
		if slice.contains(enemy.hexagon_types, hexagon_type) && !has_spell(player.clump, spell) do return hexagon_type
	}
	
	shuffled := shuffle_slice(enemy.hexagon_types)
	
	for hexagon_type in shuffled {
		if hexagon_type == .RIFLE do continue
		if hexagon_type == .HEALTH_PAD do if has_spell(player.clump, .HEALTH_PAD) do continue; else do return hexagon_type
		if hexagon_type == .ICE_BALL do if has_spell(player.clump, .ICE_BALL) do continue; else do return hexagon_type
		if hexagon_type == .FIREBALL do if has_spell(player.clump, .FIREBALL) do continue; else do return hexagon_type
		if hexagon_type == .BLACK_HOLE do if has_spell(player.clump, .BLACK_HOLE) do continue; else do return hexagon_type

		// From now on, it's guaranteed that the hexagon is an upgrade
		spell := hexagon_to_spell(hexagon_type)
		if spell == nil || (spell != nil && has_spell(player.clump, spell.?)) {
			hexagon_amounts := get_hexagon_type_amounts(player.clump)
			if hexagon_amounts[hexagon_type] > 2 do continue // Max of 3 upgrades
			return hexagon_type
		}
	}

	delete(shuffled)

	return nil
}

manage_ai_state :: proc(enemy: ^Enemy, is_clump_close: bool, closest_clump: ^Hexagon_Clump) {
	if !is_clump_close { set_ai_state(enemy, .ROAM); return }
	if enemy.health <= 20 { set_ai_state(enemy, .PANIC); return }
	if enemy.attacker != nil && enemy.ai_state != .PANIC { set_ai_state(enemy, .AGGRO); return }
	set_ai_state(enemy, .INSPECT)
}

set_ai_state :: proc(enemy: ^Enemy, state: AI_State) {
	if enemy.ai_state != state do enemy.turn_timer.start_time = f32(rl.GetTime()) - enemy.turn_timer.duration
	if enemy.ai_state != state do enemy.attack_timer.start_time = f32(rl.GetTime()) - enemy.attack_timer.duration
	enemy.ai_state = state
}

get_enemy_inaccuracy :: proc(state: AI_State) -> f32 {
	switch state {
	case .ROAM,.INSPECT: return 15
	case .AGGRO: return 10
	case .PANIC: return 25
	}
	
	return 0
}

get_closest_clump_to_enemy :: proc(enemy: ^Enemy, range: f32) -> (found: bool, clump: ^Hexagon_Clump) {
	closest_dist := range
	closest_clump: ^Hexagon_Clump = nil
	
	level := f32(get_level(enemy.hexagon_types))
	for other_clump in hexagon_clumps[:clump_cap] {
		if enemy.uuid == other_clump.uuid do continue
		other_level := f32(get_level(other_clump.hexagon_types))
		dist := rl.Vector2Distance(enemy.pos, other_clump.pos) - HEXAGON_SIZE * (level + other_level - 2)
		if dist >= range do continue
		if dist < closest_dist {
			closest_dist = dist
			closest_clump = other_clump
		}
	}

	return closest_dist < range, closest_clump
}

draw_enemies :: proc() { for enemy in enemies do draw_enemy(enemy) }

draw_enemy :: proc(enemy: Enemy) {
	draw_clump(enemy.clump)
	draw_enemy_face(enemy)
	if debug_on do draw_debug_text(enemy.pos, "%.0f hp, %v, %v, %s", enemy.health, enemy.ai_state, enemy.vel, clump_uuid_str(enemy.uuid))
}

get_detection_range :: proc(hexagon_types: []Hexagon_Type) -> f32 {
	return HEXAGON_SIZE * f32(get_level(hexagon_types)) * 2 + 300
}

// AI Helpers

enemy_attack :: proc(enemy: ^Enemy, target: rl.Vector2, spell_chance: f32, spell_weights: [Spell_Type]int) {
	if !clump_intersects_rec(enemy.clump, get_world_camera_rec()) do return
	should_use_rifle := true
	num := rand.float32_range(0, 100)
	if spell_chance > num do should_use_rifle = false

	if should_use_rifle {
		enemy_fire_pellet(enemy, target)
	} else {
		if !enemy_do_random_spell(enemy, target, spell_weights) do enemy_fire_pellet(enemy, target)
	}
}

enemy_do_random_spell :: proc(enemy: ^Enemy, target: rl.Vector2, spell_weights: [Spell_Type]int) -> bool {
	sum := spell_weights[.HEALTH_PAD] + spell_weights[.ICE_BALL] + spell_weights[.FIREBALL] + spell_weights[.BLACK_HOLE]
	if sum <= 0 do return false
	num := rand.int_range(0, sum)

	preferred: Spell_Type
	switch {
	case num < spell_weights[.HEALTH_PAD]: preferred = .HEALTH_PAD
	case num < spell_weights[.HEALTH_PAD] + spell_weights[.ICE_BALL]: preferred = .ICE_BALL
	case num < spell_weights[.HEALTH_PAD] + spell_weights[.ICE_BALL] + spell_weights[.FIREBALL]: preferred = .FIREBALL
	case: preferred = .BLACK_HOLE
	}

	spell_order: [len(Spell_Type)]Spell_Type
	switch preferred {
	case .HEALTH_PAD: spell_order = {.HEALTH_PAD, .ICE_BALL, .FIREBALL, .BLACK_HOLE}
	case .ICE_BALL: spell_order = {.ICE_BALL, .FIREBALL, .BLACK_HOLE, .HEALTH_PAD}
	case .FIREBALL: spell_order = {.FIREBALL, .BLACK_HOLE, .HEALTH_PAD, .ICE_BALL}
	case .BLACK_HOLE: spell_order = {.BLACK_HOLE, .HEALTH_PAD, .ICE_BALL, .FIREBALL}
	}

	for spell in spell_order {
		if spell_weights[spell] == 0 do continue
		if enemy.spell_cooldowns[spell] > 0 do continue
		if !has_spell(enemy.clump, spell) do continue

		enemy_do_spell(enemy, spell, target)
		return true
	}
	
	return false
}

// AI States

@(private = "file")
handle_roaming_state :: proc(enemy: ^Enemy) {
	update_timer(&enemy.turn_timer)
	if enemy.turn_timer.ding {
		enemy.turn_timer.duration = rand.float32_range(2, 10)

		// Choose random velocity to use
		enemy.target_vel.x = union_range_rand({20, 60})
		enemy.target_vel.y = union_range_rand({20, 60})
	}
}

@(private = "file")
handle_inspect_state :: proc(enemy: ^Enemy, target: ^Hexagon_Clump) {
	update_timer(&enemy.turn_timer)
	update_timer(&enemy.attack_timer)

	// Move towards the target, but not completely (like to the side)
	if enemy.turn_timer.ding {
		enemy.turn_timer.duration = rand.float32_range(2, 3)
		rot := rotation_from_points(enemy.pos, target.pos) + union_range_rand({30, 50})
		enemy.target_vel = velocity_from_rotation(rot) * rand.float32_range(40, 60)
	}

	// Fire, but not too frequently, see if target responds
	if enemy.attack_timer.ding {
		enemy.attack_timer.duration = rand.float32_range(7, 12)
		spell_weights := [Spell_Type]int{.HEALTH_PAD = 0, .ICE_BALL = 1, .FIREBALL = 1, .BLACK_HOLE = 0}
		enemy_attack(enemy, target.pos, 10, spell_weights)
	}
}

@(private = "file")
handle_aggro_state :: proc(enemy: ^Enemy, target: ^Hexagon_Clump) {
	update_timer(&enemy.turn_timer)
	update_timer(&enemy.attack_timer)

	// Move towards the target
	if enemy.turn_timer.ding {
		enemy.turn_timer.duration = rand.float32_range(1, 2)
		dist := rl.Vector2Distance(enemy.pos, target.pos)

		rot_modifier: f32
		switch {
		case dist < 100: rot_modifier = 150
		case dist < 200: rot_modifier = 60
		}
		
		rot := rotation_from_points(enemy.pos, target.pos) + union_range_rand({10, 20}) + rot_modifier
		enemy.target_vel = velocity_from_rotation(rot) * rand.float32_range(60, 70)
	}

	// Sprint to catch up to target
	if rl.Vector2Distance(enemy.pos, target.pos) > 300 && enemy.sprint_secs > 0 {
		enemy.sprinting = true
	}

	// Fire as fast as possible
	if enemy.attack_timer.ding {
		_, _, fire_rate := get_rifle_stats(get_hexagon_type_amounts(enemy.clump))
		enemy.attack_timer.duration = fire_rate * rand.float32_range(3, 3.5)
		spell_weights := [Spell_Type]int{.HEALTH_PAD = 0, .ICE_BALL = 2, .FIREBALL = 2, .BLACK_HOLE = 1}
		enemy_attack(enemy, target.pos, 25, spell_weights)
	}
}

@(private = "file")
handle_panic_state :: proc(enemy: ^Enemy, attacker: ^Hexagon_Clump) {
	update_timer(&enemy.turn_timer)
	update_timer(&enemy.attack_timer)

	// Move away from the target
	if enemy.turn_timer.ding {
		enemy.turn_timer.duration = rand.float32_range(0.5, 1)
		rot := rotation_from_points(enemy.pos, attacker.pos) + union_range_rand({10, 20}) + 180 // We add 180 so that direction flips
		enemy.target_vel = velocity_from_rotation(rot) * rand.float32_range(60, 70)
	}

	// Sprint if it can
	if enemy.sprint_secs > 0 {
		enemy.sprinting = true
	}

	// Fire as much as it can, while running away
	if enemy.attack_timer.ding {
		_, _, fire_rate := get_rifle_stats(get_hexagon_type_amounts(enemy.clump))
		enemy.attack_timer.duration = fire_rate * rand.float32_range(4, 4.5)
		spell_weights := [Spell_Type]int{.HEALTH_PAD = 3, .ICE_BALL = 0, .FIREBALL = 0, .BLACK_HOLE = 1}
		enemy_attack(enemy, attacker.pos, 50, spell_weights)
	}
}