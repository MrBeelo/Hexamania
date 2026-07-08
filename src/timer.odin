package main

import rl "vendor:raylib"

Timer :: struct {
	duration: f32,
	start_time: f32,
	active: bool,
	repeat: bool,
	ding: bool,
}

NewTimer :: proc(duration: f32, repeat: bool, auto_start := false, begin_now := false) -> Timer {
	timer := Timer{duration, 0, false, repeat, false}
	if auto_start do ActivateTimer(&timer)
	if begin_now do timer.start_time = f32(rl.GetTime()) - timer.duration
	return timer
}

ActivateTimer :: proc(timer: ^Timer) {
	timer.active = true
	timer.start_time = f32(rl.GetTime())
}

DeactivateTimer :: proc(timer: ^Timer) {
	if timer.repeat do ActivateTimer(timer); else do FinishTimer(timer)
}

FinishTimer :: proc(timer: ^Timer) {
	timer.ding = false
	timer.active = false
}

GetElapsedTime :: proc(timer: ^Timer) -> f32 {
	return f32(rl.GetTime()) - timer.start_time
}

GetRemainingTime :: proc(timer: ^Timer) -> f32 {
	return timer.duration - GetElapsedTime(timer)
}

UpdateTimer :: proc(timer: ^Timer) {
	timer.ding = false
	if timer.active && GetRemainingTime(timer) <= 0 {
		DeactivateTimer(timer)
		timer.ding = true
	}	
}