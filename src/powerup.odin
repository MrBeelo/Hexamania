package main

import "core:math"
import "core:math/rand"
import rl "raylib"

POWERUP_DECELERATION :: 5 * 60
POWERUP_SIZE :: f32(32)
BOUND_POWERUP_TIME :: 10
POWERUP_SRC_SIZE :: 256
world_powerups: [dynamic]World_Powerup
powerup_sheet: rl.Texture2D
powerup_spawn_timer: Timer

// Because for some reason union lengths aren't known at compile time, PowerupType
// will be a regular enum, and the Powerup will have a "value" field that changes
// how the powerup behaves, below is what "value" does for each PowerupType
Powerup_Type :: enum {
	HEALTH, // Value: Amount of health to add over a specific period of time
	DAMAGE, // Value: Damage multiplier (1 doesn't change anything)
	SPEED, // Value: Speed multiplier (1 doesn't change anything)
}

// It's important to distinguish the two different kinds of "powerups".
// World powerups are like hearts, they appear in world space.
// Bound powerups are the active powerups the player has consumed.

World_Powerup :: struct {
	type:    Powerup_Type,
	value:   f32,
	pos:     rl.Vector2,
	vel:     rl.Vector2,
	hurtbox: rl.Rectangle,
}

Bound_Powerup :: struct {
	value:          f32,
	time_remaining: f32,
}

throw_random_world_powerup :: proc(pos: rl.Vector2) {
	type := rand.choice_enum(Powerup_Type)

	value: f32
	switch type {
	case .HEALTH:
		value = rand.float32_range(30, 70)
	case .DAMAGE:
		value = rand.float32_range(1.3, 1.8)
	case .SPEED:
		value = rand.float32_range(1.5, 2)
	}

	vel_x := union_range_rand({100, 150})
	vel_y := union_range_rand({100, 150})

	append(&world_powerups, World_Powerup{type, value, pos, {vel_x, vel_y}, {}})
}

update_world_powerups :: proc() {
	for &powerup, index in world_powerups do update_world_powerup(&powerup, index)

	// Spawning powerups
	update_timer(&powerup_spawn_timer)
	if powerup_spawn_timer.ding do spawn_world_powerup()
}

spawn_world_powerup :: proc() {
	if player.camera.zoom == 0 do return
	pos := get_random_spawn_pos()
	throw_random_world_powerup(pos)
	powerup_spawn_timer.duration = rand.float32_range(20, 30)
}

update_world_powerup :: proc(powerup: ^World_Powerup, index: int) {
	powerup.pos += powerup.vel * rl.GetFrameTime()
	accelerate(&powerup.vel.x, 0, POWERUP_DECELERATION)
	accelerate(&powerup.vel.y, 0, POWERUP_DECELERATION)

	DEADZONE :: f32(3)
	if math.abs(powerup.vel.x) < DEADZONE do powerup.vel.x = 0
	if math.abs(powerup.vel.y) < DEADZONE do powerup.vel.y = 0

	powerup.hurtbox = rl.Rectangle {
		powerup.pos.x - POWERUP_SIZE / 2,
		powerup.pos.y - POWERUP_SIZE / 2,
		POWERUP_SIZE,
		POWERUP_SIZE,
	}

	RANGE :: f32(100)
	lowest_dist := RANGE
	closest_box: rl.Rectangle
	for hexagon in player.clump.hexagons {
		dist := rl.Vector2Distance(powerup.pos, hexagon.center)
		if dist >= RANGE do continue
		if dist < lowest_dist {
			lowest_dist = dist
			closest_box = hexagon.hurtbox
		}
	}

	if lowest_dist < RANGE do powerup.vel = velocity_from_points(powerup.pos, player.pos) * (100 - lowest_dist)

	if rl.CheckCollisionRecs(closest_box, powerup.hurtbox) {
		if len(world_powerups) > index do unordered_remove(&world_powerups, index)
		play_sound(merge, 0.7)
		player_action_list.found_powerup = true

		value := powerup.value
		if player.bound_powerups[powerup.type].time_remaining > 0 do value = math.max(player.bound_powerups[powerup.type].value, powerup.value)
		time_remaining := player.bound_powerups[powerup.type].time_remaining + BOUND_POWERUP_TIME
		player.bound_powerups[powerup.type] = Bound_Powerup{value, time_remaining}

		// Add health as soon as bound powerup is acquired
		if powerup.type == .HEALTH do heal_clump(&player.clump, powerup.value)
	}

	// Despawn if away from player
	player_dist := rl.Vector2Distance(powerup.pos, player.pos)
	player_dist -= f32(get_level(player.hexagon_types) - 1) * HEXAGON_SIZE
	if player_dist > 1000 && len(world_powerups) > index do unordered_remove(&world_powerups, index)
}

draw_world_powerups :: proc() {for powerup in world_powerups do draw_world_powerup(powerup)}

draw_world_powerup :: proc(powerup: World_Powerup) {
	src := rl.Rectangle {
		f32(int(powerup.type)) * POWERUP_SRC_SIZE,
		0,
		POWERUP_SRC_SIZE,
		POWERUP_SRC_SIZE,
	}
	dest := powerup.hurtbox // The destination rectangle and the hurtbox happen to be the same :)
	rl.DrawTexturePro(powerup_sheet, src, dest, {}, 0, rl.WHITE)
}

update_bound_powerups :: proc(bound_powerups: ^[Powerup_Type]Bound_Powerup) {
	for &powerup in bound_powerups {
		if powerup.time_remaining > 0 do powerup.time_remaining -= rl.GetFrameTime()
		powerup.time_remaining = math.max(powerup.time_remaining, 0) // Sets the minimum value of this to 0, as a safeguard
	}
}

load_powerups :: proc() {
	powerup_sheet = rl.LoadTexture("texture/powerup_sheet.png")
	powerup_spawn_timer = new_timer(20, true, true)
}

unload_powerups :: proc() {
	rl.UnloadTexture(powerup_sheet)
}
