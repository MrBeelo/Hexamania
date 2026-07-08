package main

import rl "vendor:raylib"
import "core:math"
import "core:math/rand"

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

RotationFrom2Points :: proc(p1: rl.Vector2, p2: rl.Vector2) -> f32 {
	return math.atan2(p2.y - p1.y, p2.x - p1.x) * RAD2DEG + 90
}

VelocityFromRotation :: proc(rot: f32) -> rl.Vector2 {
	return {math.cos(rot * DEG2RAD - PI / 2), math.sin(rot * DEG2RAD - PI / 2)}
}

VelocityFrom2Points :: proc(p1: rl.Vector2, p2: rl.Vector2) -> rl.Vector2 {
	return VelocityFromRotation(RotationFrom2Points(p1, p2))
}

RoundToNearest :: proc(x: f32, to: f32) -> f32 {
	return math.round(x / to) * to
}

RoundDownToNearest :: proc(x: f32, to: f32) -> f32 {
	return math.floor(x / to) * to
}

// Given a range, returns a number within it, and randomly selects if it is
// positive or negative
RangeRand :: proc(range: rl.Vector2) -> f32 {
	abs := rand.float32_range(range.x, range.y)
	sign := rand.int_range(0, 2) // Sign: Either 0 or 1
	if sign == 0 do sign = -1 // Sign: Either -1 or 1
	return abs * f32(sign)
}