package main

import rl "raylib"

Timer :: struct {
	duration: f32,
	start_time: f32,
	active: bool,
	repeat: bool,
	ding: bool,
}

new_timer :: proc(duration: f32, repeat: bool, auto_start := false, begin_now := false) -> Timer {
	timer := Timer{duration, 0, false, repeat, false}
	if auto_start do activate_timer(&timer)
	if begin_now do timer.start_time = f32(rl.GetTime()) - timer.duration
	return timer
}

activate_timer :: proc(timer: ^Timer) {
	timer.active = true
	timer.start_time = f32(rl.GetTime())
}

deactivate_timer :: proc(timer: ^Timer) {
	if timer.repeat do activate_timer(timer); else do finish_timer(timer)
}

finish_timer :: proc(timer: ^Timer) {
	timer.ding = false
	timer.active = false
}

get_elapsed_timer_time :: proc(timer: ^Timer) -> f32 {
	return f32(rl.GetTime()) - timer.start_time
}

get_remaining_timer_time :: proc(timer: ^Timer) -> f32 {
	return timer.duration - get_elapsed_timer_time(timer)
}

update_timer :: proc(timer: ^Timer) {
	timer.ding = false
	if timer.active && get_remaining_timer_time(timer) <= 0 {
		deactivate_timer(timer)
		timer.ding = true
	}	
}