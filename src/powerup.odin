package main

import rl "vendor:raylib"
import "core:math"
import "core:math/rand"

POWERUP_DECELERATION :: 5 * 60
POWERUP_SIZE :: f32(32)
BOUND_POWERUP_TIME :: 10
world_powerups: [dynamic]WorldPowerup
powerup_textures: [PowerupType]rl.Texture2D
powerup_spawn_timer: Timer

// Because for some reason union lengths aren't known at compile time, PowerupType
// will be a regular enum, and the Powerup will have a "value" field that changes
// how the powerup behaves, below is what "value" does for each PowerupType
PowerupType :: enum {
	HEALTH, // Value: Amount of health to add over a specific period of time
	DAMAGE, // Value: Damage multiplier (1 doesn't change anything)
	SPEED, // Value: Speed multiplier (1 doesn't change anything)
}

WorldPowerup :: struct {
	type: PowerupType,
	value: f32,
	pos: rl.Vector2,
	vel: rl.Vector2,
	hurtbox: rl.Rectangle,
}

BoundPowerup :: struct {
	value: f32,
	time_remaining: f32,
}

ThrowRandomWorldPowerup :: proc(pos: rl.Vector2) {
	type := rand.choice_enum(PowerupType)

	value: f32
	switch type {
	case .HEALTH: value = rand.float32_range(30, 70)
	case .DAMAGE: value = rand.float32_range(1.3, 1.8)
	case .SPEED: value = rand.float32_range(1.5, 2)
	}

	vel_x := RangeRand({100, 150})
	vel_y := RangeRand({100, 150})
	
	append(&world_powerups, WorldPowerup{type, value, pos, {vel_x, vel_y}, {}})
}

UpdateWorldPowerups :: proc() { 
	for &powerup, index in world_powerups do UpdateWorldPowerup(&powerup, index)

	// Spawning powerups
	UpdateTimer(&powerup_spawn_timer)
	if powerup_spawn_timer.ding {
		if player.camera.zoom == 0 do return
		pos := GetRandomSpawnPos()
		ThrowRandomWorldPowerup(pos)
		powerup_spawn_timer.duration = rand.float32_range(20, 30)
	}
}

UpdateWorldPowerup :: proc(powerup: ^WorldPowerup, index: int) {	
	powerup.pos += powerup.vel * rl.GetFrameTime()
	Accelerate(&powerup.vel.x, 0, POWERUP_DECELERATION)
	Accelerate(&powerup.vel.y, 0, POWERUP_DECELERATION)

	DEADZONE :: f32(3)
	if math.abs(powerup.vel.x) < DEADZONE do powerup.vel.x = 0
	if math.abs(powerup.vel.y) < DEADZONE do powerup.vel.y = 0
	
	powerup.hurtbox = rl.Rectangle{powerup.pos.x - POWERUP_SIZE / 2, powerup.pos.y - POWERUP_SIZE / 2, POWERUP_SIZE, POWERUP_SIZE}

	RANGE :: f32(100)
	lowest_dist := RANGE
	closest_box: rl.Rectangle
	for hexagon in GetClumpHexagons(player.clump) {
		dist := rl.Vector2Distance(powerup.pos, hexagon.center)
		if dist >= RANGE do continue
		if dist < lowest_dist {
			lowest_dist = dist
			closest_box = hexagon.hurtbox
		}
	}

	if lowest_dist < RANGE do powerup.vel = VelocityFrom2Points(powerup.pos, player.pos) * (100 - lowest_dist)
	
	if rl.CheckCollisionRecs(closest_box, powerup.hurtbox) {
		if len(world_powerups) > index do unordered_remove(&world_powerups, index)

		value := powerup.value
		if player.bound_powerups[powerup.type].time_remaining > 0 do value = math.max(player.bound_powerups[powerup.type].value, powerup.value)
		time_remaining := player.bound_powerups[powerup.type].time_remaining + BOUND_POWERUP_TIME
		player.bound_powerups[powerup.type] = BoundPowerup{value, time_remaining}

		// Add health as soon as bound powerup is acquired
		if powerup.type == .HEALTH do player.health += powerup.value
	}

	// Despawn if away from player
	player_dist := rl.Vector2Distance(powerup.pos, player.pos)
	player_dist -= f32(GetPlayerLevel(player) - 1) * HEXAGON_SIZE
	if player_dist > 1000 && len(world_powerups) > index do unordered_remove(&world_powerups, index)
}

DrawWorldPowerups :: proc() { for powerup in world_powerups do DrawWorldPowerup(powerup) }

DrawWorldPowerup :: proc(powerup: WorldPowerup) {
	texture := powerup_textures[powerup.type]
	src := rl.Rectangle{0, 0, f32(texture.width), f32(texture.height)}
	dest := powerup.hurtbox // The destination rectangle and the hurtbox happen to be the same :)
	rl.DrawTexturePro(texture, src, dest, {}, 0, rl.WHITE)
}

UpdateBoundPowerups :: proc(bound_powerups: ^[PowerupType]BoundPowerup) {
	for &powerup in bound_powerups {
		if powerup.time_remaining > 0 do powerup.time_remaining -= rl.GetFrameTime()
		powerup.time_remaining = math.max(powerup.time_remaining, 0) // Sets the minimum value of this to 0, as a safeguard
	}
}

LoadPowerups :: proc() {
	powerup_textures = {
		.HEALTH = rl.LoadTexture("res/powerup/health.png"),
		.DAMAGE = rl.LoadTexture("res/powerup/damage.png"),
		.SPEED = rl.LoadTexture("res/powerup/speed.png"),
	}

	powerup_spawn_timer = NewTimer(20, true, true)
}

UnloadPowerups :: proc() {
	for texture in powerup_textures do rl.UnloadTexture(texture)
}