package main

import rl "vendor:raylib"
import "core:encoding/uuid"
import "core:math/rand"

PELLET_SPEED :: 5 * 60
pellets: [dynamic]Pellet

Pellet :: struct {
	pos: rl.Vector2,
	vel: rl.Vector2,
	owner: uuid.Identifier,
	pellet_multipliers: struct{ speed_mult: f32, damage_mult: f32 },
}

PlayerFirePellet :: proc() {
	vel := VelocityFrom2Points(CameraPos(player), rl.GetMousePosition())
	player.rifle_delay = GetRifleDelay(player.clump)
	append(&pellets, Pellet{player.pos, vel, player.uuid, GetPelletMultipliers(player.clump)})
}

GetRifleDelay :: proc(clump: HexagonClump) -> f32 {
	return 0.5 - f32(GetHexagonTypeAmounts(player.clump)[.RIFLE_UPGRADE_FIRE_RATE]) * 0.07
}

EnemyFirePellet :: proc(enemy: ^Enemy, target: rl.Vector2) {
	if enemy.rifle_delay > 0 do return
	
	// Change the enemy's inaccuracy factor based on its AI state
	inaccuracy := GetEnemyInaccuracy(enemy.ai_state)
	
	rot := RotationFrom2Points(enemy.pos, target)
	rot += rand.float32_range(-inaccuracy, inaccuracy) // Enemy inaccuracies!
	vel := VelocityFromRotation(rot)

	enemy.rifle_delay = GetRifleDelay(enemy.clump)
	
	append(&pellets, Pellet{enemy.pos, vel, enemy.uuid, GetPelletMultipliers(enemy.clump)})
}

GetPelletMultipliers :: proc(clump: HexagonClump) -> struct{ speed_mult: f32, damage_mult: f32 } {
	hexagon_type_amounts := GetHexagonTypeAmounts(clump)
	speed_mult := 1 + f32(hexagon_type_amounts[.RIFLE_UPGRADE_PELLET_SPEED]) * 2 / 5
	damage_mult := 1 + f32(hexagon_type_amounts[.RIFLE_UPGRADE_DAMAGE]) * 3 / 10
	return {speed_mult, damage_mult}
}

UpdatePellets :: proc() { for &pellet, index in pellets do UpdatePellet(&pellet, index) }

UpdatePellet :: proc(pellet: ^Pellet, index: int) {
	pellet.pos += pellet.vel * PELLET_SPEED * rl.GetFrameTime()
	if rl.Vector2Distance(pellet.pos, player.pos) > screen_size.x do if len(pellets) > index do unordered_remove(&pellets, index)

	for clump in GetAllClumps() do if clump.uuid != pellet.owner && clump.grace_period <= 0 do for hexagon in GetClumpHexagons(clump^) {
		if rl.Vector2Distance(pellet.pos, hexagon.center) > 100 do continue
		if rl.CheckCollisionPointRec(pellet.pos, hexagon.hurtbox) {
			DamageClump(clump, 10, GetClumpFromUUID(pellet.owner))
			if len(pellets) > index do unordered_remove(&pellets, index)
		}
	}
}

DrawPellets :: proc() { for pellet in pellets do DrawPellet(pellet) }

DrawPellet :: proc(pellet: Pellet) {
	rl.DrawCircleV(pellet.pos, 3, rl.WHITE)
	if debug_on do DrawDebugText(pellet.pos, "Owner: %s", ShortUUID(pellet.owner))
}