package main

import rl "vendor:raylib"
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

PlayerFirePellet :: proc() {
	if !player.can_shoot do return
	vel := VelocityFrom2Points(CameraPos(player), rl.GetMousePosition())
	speed, damage, fire_rate := GetRifleStats(GetHexagonTypeAmounts(player.clump))
	player.rifle_delay = fire_rate
	append(&pellets, Pellet{player.pos, vel, player.uuid, speed, damage})
	rl.SetSoundVolume(shoot, 1)
	rl.PlaySound(shoot)
}

EnemyFirePellet :: proc(enemy: ^Enemy, target: rl.Vector2) {
	if !enemy.can_shoot do return
	if enemy.rifle_delay > 0 do return
	
	// Change the enemy's inaccuracy factor based on its AI state
	inaccuracy := GetEnemyInaccuracy(enemy.ai_state)
	
	rot := RotationFrom2Points(enemy.pos, target)
	rot += rand.float32_range(-inaccuracy, inaccuracy) // Enemy inaccuracies!
	vel := VelocityFromRotation(rot)

	speed, damage, fire_rate := GetRifleStats(GetHexagonTypeAmounts(enemy.clump))
	
	enemy.rifle_delay = fire_rate
	
	append(&pellets, Pellet{enemy.pos, vel, enemy.uuid, speed, damage})
}

GetRifleStats :: proc(hexagon_type_amounts: [HexagonType]int) -> (speed: f32, damage: f32, fire_rate: f32) {
	speed = 380 * (1 + f32(hexagon_type_amounts[.RIFLE_UPGRADE_PELLET_SPEED]) * 1 / 5)
	damage = 9 * (1 + f32(hexagon_type_amounts[.RIFLE_UPGRADE_DAMAGE]) * 3 / 10)
	fire_rate = 0.5 - f32(GetHexagonTypeAmounts(player.clump)[.RIFLE_UPGRADE_FIRE_RATE]) * 0.05
	return speed, damage, fire_rate
}

UpdatePellets :: proc() { for &pellet, index in pellets do UpdatePellet(&pellet, index) }

UpdatePellet :: proc(pellet: ^Pellet, index: int) {
	pellet.pos += pellet.vel * pellet.speed * rl.GetFrameTime()
	if rl.Vector2Distance(pellet.pos, player.pos) > screen_size.x do if len(pellets) > index do unordered_remove(&pellets, index)

	for clump in GetAllClumps() do if clump.uuid != pellet.owner && clump.grace_period <= 0 do for hexagon in GetClumpHexagons(clump^) {
		if rl.Vector2Distance(pellet.pos, hexagon.center) > 100 do continue
		if rl.CheckCollisionPointRec(pellet.pos, hexagon.hurtbox) {
			DamageClump(clump, pellet.damage, GetClumpFromUUID(pellet.owner))
			if len(pellets) > index do unordered_remove(&pellets, index)
		}
	}
}

DrawPellets :: proc() { for pellet in pellets do DrawPellet(pellet) }

DrawPellet :: proc(pellet: Pellet) {
	rl.DrawCircleV(pellet.pos, 3, rl.WHITE)
	if debug_on do DrawDebugText(pellet.pos, "Owner: %s", ShortUUID(pellet.owner))
}