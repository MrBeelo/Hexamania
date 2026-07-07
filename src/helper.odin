package main

import rl "vendor:raylib"
import "core:math"

PI :: 3.141
DEG2RAD :: PI / 180
RAD2DEG :: 180 / PI

RotatePoint :: proc(point: rl.Vector2, pivot: rl.Vector2, rot: f32) -> rl.Vector2 {
	delta := point - pivot
	rad_rot := rot * PI / 180
	pos_x := pivot.x + delta.x * math.cos(rad_rot) - (delta.y * math.sin(rad_rot))
	pos_y := pivot.y + delta.x * math.sin(rad_rot) + delta.y * math.cos(rad_rot)
	return {pos_x, pos_y}
}

RotationFromPointToMouse :: proc(point: rl.Vector2, mouse: rl.Vector2) -> f32 {
	return math.atan2(mouse.y - point.y, mouse.x - point.x) * RAD2DEG + 90
}