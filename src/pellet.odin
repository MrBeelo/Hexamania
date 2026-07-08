package main

import rl "vendor:raylib"
import "core:math"

PELLET_SPEED :: 10 * 60
pellets: [dynamic]Pellet

Pellet :: struct {
	pos: rl.Vector2,
	rot: f32,
	vel: rl.Vector2,
	player_owned: bool,
}

PlayerFirePellet :: proc() {
	pos := player.pos
	rot := RotationFrom2Points(CameraPos(player), rl.GetMousePosition())
	vel := rl.Vector2{math.cos(rot * DEG2RAD - PI / 2), math.sin(rot * DEG2RAD - PI / 2)}
	append(&pellets, Pellet{pos, rot, vel, true})
}

UpdatePellets :: proc() { for &pellet, index in pellets do UpdatePellet(&pellet, index) }

UpdatePellet :: proc(pellet: ^Pellet, index: int) {
	pellet.pos += pellet.vel * PELLET_SPEED * rl.GetFrameTime()
	if rl.Vector2Distance(pellet.pos, player.pos) > screen_size.x do unordered_remove(&pellets, index)

	if pellet.player_owned do for &enemy in enemies do for hexagon in GetClumpHexagons(enemy.clump) do if rl.Vector2Distance(pellet.pos, hexagon.center) < 100 {
		if rl.CheckCollisionPointRec(pellet.pos, hexagon.hurtbox) {
			enemy.health -= 30
			unordered_remove(&pellets, index)
		}
	}
}

DrawPellets :: proc() { for pellet in pellets do DrawPellet(pellet) }

DrawPellet :: proc(pellet: Pellet) {
	rl.DrawCircleV(pellet.pos, 3, rl.WHITE)
}