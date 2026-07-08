package main

import rl "vendor:raylib"

Stopwatch :: struct {
	active: bool,
	start_time: f32,
	stop_time: f32,
}

StartStopwatch :: proc(stopwatch: ^Stopwatch) {
	stopwatch.active = true
	stopwatch.start_time = f32(rl.GetTime())
}

StopStopwatch :: proc(stopwatch: ^Stopwatch) {
	if !stopwatch.active do return
	stopwatch.active = false
	stopwatch.stop_time = f32(rl.GetTime())
}

GetElapsedStopwatchTime :: proc(stopwatch: Stopwatch) -> f32 {
	stop_time := f32(rl.GetTime()) if stopwatch.active else stopwatch.stop_time
	return stop_time - stopwatch.start_time
}