package main

import rl "raylib"
import "core:encoding/uuid"
import "core:math/rand"

PELLET_BASE_DAMAGE :: 10
PELLET_BASE_SPEED :: 5 * 60
pellets: [dynamic]Pellet

Pellet :: struct {
	pos: rl.Vector2,
	vel: rl.Vector2,
	owner: uuid.Identifier,
	speed: f32,
	damage: f32,
}

player_fire_pellet :: proc() {
	if !player.can_shoot do return
	vel := velocity_from_points(world_to_camera(player.pos), rl.GetMousePosition())
	speed, damage, fire_rate := get_rifle_stats(get_hexagon_type_amounts(player.clump))
	player.rifle_delay = fire_rate
	append(&pellets, Pellet{player.pos, vel, player.uuid, speed, damage})
	play_sound(shoot)
}

enemy_fire_pellet :: proc(enemy: ^Enemy, target: rl.Vector2) {
	if !enemy.can_shoot do return
	if enemy.rifle_delay > 0 do return
	
	// Change the enemy's inaccuracy factor based on its AI state
	inaccuracy := get_enemy_inaccuracy(enemy.ai_state)
	
	rot := rotation_from_points(enemy.pos, target)
	rot += rand.float32_range(-inaccuracy, inaccuracy) // Enemy inaccuracies!
	vel := velocity_from_rotation(rot)

	speed, damage, fire_rate := get_rifle_stats(get_hexagon_type_amounts(enemy.clump))
	
	enemy.rifle_delay = fire_rate

	play_sound(shoot, enemy.clump, player.clump)
	
	append(&pellets, Pellet{enemy.pos, vel, enemy.uuid, speed, damage})
}

get_rifle_stats :: proc(hexagon_type_amounts: [Hexagon_Type]int) -> (speed: f32, damage: f32, fire_rate: f32) {
	speed = 380 * (1 + f32(hexagon_type_amounts[.RIFLE_UPGRADE_PELLET_SPEED]) * 1 / 5)
	damage = 9 * (1 + f32(hexagon_type_amounts[.RIFLE_UPGRADE_DAMAGE]) * 3 / 10)
	fire_rate = 0.5 - f32(get_hexagon_type_amounts(player.clump)[.RIFLE_UPGRADE_FIRE_RATE]) * 0.05
	return speed, damage, fire_rate
}

update_pellets :: proc() { for &pellet, index in pellets do update_pellet(&pellet, index) }

update_pellet :: proc(pellet: ^Pellet, index: int) {
	pellet.pos += pellet.vel * pellet.speed * rl.GetFrameTime()
	if rl.Vector2Distance(pellet.pos, player.pos) > SCREEN_SIZE.x do if len(pellets) > index do unordered_remove(&pellets, index)

	for clump in hexagon_clumps[:clump_cap] do if clump.uuid != pellet.owner && clump.grace_period <= 0 do for hexagon in clump.hexagons {
		if rl.Vector2Distance(pellet.pos, hexagon.center) > 100 do continue
		if rl.CheckCollisionPointRec(pellet.pos, hexagon.hurtbox) {
			damage_clump(clump, pellet.damage, get_clump_from_uuid(pellet.owner))
			if len(pellets) > index do unordered_remove(&pellets, index)
		}
	}
}

draw_pellets :: proc() { for pellet in pellets do draw_pellet(pellet) }

draw_pellet :: proc(pellet: Pellet) {
	rl.DrawCircleV(pellet.pos, 3, rl.WHITE)
	if debug_on do draw_debug_text(pellet.pos, "Owner: %s", clump_uuid_str(pellet.owner))
}