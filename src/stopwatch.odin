package main

import rl "raylib"

Stopwatch :: struct {
	active: bool,
	start_time: f32,
	stop_time: f32,
}

start_stopwatch :: proc(stopwatch: ^Stopwatch) {
	stopwatch.active = true
	stopwatch.start_time = f32(rl.GetTime())
}

stop_stopwatch :: proc(stopwatch: ^Stopwatch) {
	if !stopwatch.active do return
	stopwatch.active = false
	stopwatch.stop_time = f32(rl.GetTime())
}

get_elapsed_stopwatch_time :: proc(stopwatch: Stopwatch) -> f32 {
	stop_time := f32(rl.GetTime()) if stopwatch.active else stopwatch.stop_time
	return stop_time - stopwatch.start_time
}