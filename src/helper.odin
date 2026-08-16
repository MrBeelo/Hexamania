package main

import rl "raylib"
import "core:math"
import "core:math/rand"

rotate_point_around_pivot :: proc(point: rl.Vector2, pivot: rl.Vector2, rot: f32) -> rl.Vector2 {
	delta := point - pivot
	rad_rot := rot * rl.PI / 180
	pos_x := pivot.x + delta.x * math.cos(rad_rot) - (delta.y * math.sin(rad_rot))
	pos_y := pivot.y + delta.x * math.sin(rad_rot) + delta.y * math.cos(rad_rot)
	return {pos_x, pos_y}
}

rotation_from_points :: proc(p1: rl.Vector2, p2: rl.Vector2) -> f32 {
	return math.atan2(p2.y - p1.y, p2.x - p1.x) * rl.RAD2DEG + 90
}

velocity_from_rotation :: proc(rot: f32) -> rl.Vector2 {
	return {math.cos(rot * rl.DEG2RAD - rl.PI / 2), math.sin(rot * rl.DEG2RAD - rl.PI / 2)}
}

velocity_from_points :: proc(p1: rl.Vector2, p2: rl.Vector2) -> rl.Vector2 {
	return velocity_from_rotation(rotation_from_points(p1, p2))
}

round_down_to_nearest :: proc(x: f32, to: f32) -> f32 {
	return math.floor(x / to) * to
}

// Given a range, returns a number within it, and randomly selects if it is
// positive or negative
union_range_rand :: proc(range: rl.Vector2) -> f32 {
	abs := rand.float32_range(range.x, range.y)
	sign := rand.int_range(0, 2) // Sign: Either 0 or 1
	if sign == 0 do sign = -1 // Sign: Either -1 or 1
	return abs * f32(sign)
}

float_to_time_str :: proc(value: f32) -> string {
	mins := int(math.floor(value / 60))
	secs := int(math.floor(value)) % 60
	mins = math.max(mins, 0)
	secs = math.max(secs, 0)
	str := string(rl.TextFormat("%2d:%02d", mins, secs))
	return str
}

shuffle_slice :: proc(arr: []$T) -> []T {
	result := make([]T, len(arr))
	copy(result, arr)
	#reverse for _, i in result {
		j := rand.int_range(0, i + 1)
		result[i], result[j] = result[j], result[i]
	}
	return result
}