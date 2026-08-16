package main

import rl "raylib"
import "core:math"

BASE_PLAYER_SPEED :: 3 * 60
PLAYER_ACCELERATION :: 8 * 60

Player :: struct {
	using clump: Hexagon_Clump,
	camera: rl.Camera2D,
	bound_powerups: [Powerup_Type]Bound_Powerup,
	spell_mode: bool,
	active_spell: Maybe(Spell_Type),
}

new_player :: proc() -> Player {
	camera := rl.Camera2D{SCREEN_SIZE / 2, 0, 0, 1}
	return Player{ new_clump({.RIFLE, .RIFLE}, 0), camera, {}, false, nil }
}

update_player :: proc(plr: ^Player) {
	// Manage death
	if plr.dead_time > 0.5 do start_death_sequence()
	
	// Manage speed
	speed := get_player_speed(plr^)
	if holding(.HORIZ) && holding(.VERT) do speed *= (1 / 1.41)

	target_speed_modifier_x := int(holding(.RIGHT)) - int(holding(.LEFT))
	target_speed_modifier_y := int(holding(.DOWN)) - int(holding(.UP))

	accelerate(&plr.vel.x, speed * f32(target_speed_modifier_x), PLAYER_ACCELERATION)
	accelerate(&plr.vel.y, speed * f32(target_speed_modifier_y), PLAYER_ACCELERATION)

	if !player_action_list.moved && (holding(.HORIZ) || holding(.VERT)) do player_action_list.moved = true

	// Clamp velocities down to 0 if they are low and player isn't moving
	if !holding(.HORIZ) && !holding(.VERT) {
		DEADZONE :: f32(10)
		if math.abs(plr.vel.x) < DEADZONE do plr.vel.x = 0
		if math.abs(plr.vel.y) < DEADZONE do plr.vel.y = 0
	}

	plr.sprinting = holding(.SPRINT) && plr.sprint_secs > 0
	if holding(.SPRINT) do player_action_list.sprinted = true

	// Clamp player velocity for safety
	max_vel := get_max_player_velocity(plr^)
	plr.vel.x = clamp(plr.vel.x, -max_vel, max_vel)
	plr.vel.y = clamp(plr.vel.y, -max_vel, max_vel)

	// Camera Management
	handle_camera(plr)

	// Update the powerups the player has
	update_bound_powerups(&plr.bound_powerups)

	if rl.IsMouseButtonPressed(.RIGHT) {
		player_action_list.opened_spell_menu = true
		if plr.active_spell == nil {
			for spell in Spell_Type do if has_spell(plr.clump, spell) { plr.active_spell = spell; plr.spell_mode = true }
		} else {
			plr.spell_mode = !plr.spell_mode
		}
	}

	if !plr.spell_mode {
		if rl.IsMouseButtonPressed(.LEFT) && plr.rifle_delay <= 0 && player.can_shoot {
			player_action_list.shot = true
			player_fire_pellet()
		}
	} else {
		move := rl.GetMouseWheelMove()
		if move > 0 do change_player_active_spell(true, plr.active_spell.?, plr.active_spell.?)
		if move < 0 do change_player_active_spell(false, plr.active_spell.?, plr.active_spell.?)

		if rl.IsMouseButtonPressed(.LEFT) && player.spell_cooldowns[player.active_spell.?] <= 0 {
			player_action_list.used_spell = true
			player_do_spell(plr.active_spell.?)
			plr.spell_mode = false
		}
	}	

	update_clump(&plr.clump)
}

draw_player :: proc(plr: ^Player) {
	draw_clump(plr.clump)
	draw_player_face()
	if debug_on do draw_debug_text(plr.pos, "%.0f hp, %s", plr.health, clump_uuid_str(plr.uuid))
}

change_player_active_spell :: proc(up: bool, start_spell: Spell_Type, test_spell: Spell_Type) {
	index := int(test_spell)
	index += 1 if up else -1
	index %= len(Spell_Type)
	if index < 0 do index += len(Spell_Type)

	new_spell := Spell_Type(index)
	if new_spell == start_spell do return
	if has_spell(player.clump, new_spell) { player.active_spell = new_spell; return }
	change_player_active_spell(up, start_spell, new_spell)
}

get_player_speed :: proc(plr: Player) -> f32 {
	speed := f32(BASE_PLAYER_SPEED)
	if plr.bound_powerups[.SPEED].time_remaining > 0 do speed *= plr.bound_powerups[.SPEED].value
	return speed
}

@(private = "file")
get_max_player_velocity :: proc(plr: Player) -> f32 {
	max_speed := get_player_speed(plr)
	if player.sprinting do max_speed *= 1.5
	return max_speed
}