package main

import rl "vendor:raylib"
import "core:math"

PELLET_SPEED :: 10 * 60
pellets: [dynamic]Pellet

Pellet :: struct {
	pos: rl.Vector2,
	rot: f32,
	vel: rl.Vector2,
}

FirePellet :: proc() {
	pos := player.pos
	rot := RotationFromPointToMouse(CameraPos(player), rl.GetMousePosition())
	vel := rl.Vector2{math.cos(rot * DEG2RAD - PI / 2), math.sin(rot * DEG2RAD - PI / 2)}
	append(&pellets, Pellet{pos, rot, vel})
}

UpdatePellets :: proc() { for &pellet in pellets do UpdatePellet(&pellet) }

UpdatePellet :: proc(pellet: ^Pellet) {
	pellet.pos += pellet.vel * PELLET_SPEED * rl.GetFrameTime()
	if rl.Vector2Distance(pellet.pos, player.pos) > screen_size.x do pop_front(&pellets)
}

DrawPellets :: proc() { for pellet in pellets do DrawPellet(pellet) }

DrawPellet :: proc(pellet: Pellet) {
	rl.DrawCircleV(pellet.pos, 3, rl.WHITE)
}