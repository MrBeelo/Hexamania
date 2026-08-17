package main

import rl "raylib"

shoot, fire_spell, explosion, ui_confirm, damaged, merge, death, freeze: rl.Sound

@(private = "file")
play_sound_normal :: proc(sound: rl.Sound, volume := f32(1)) {
	rl.SetSoundVolume(sound, volume)
	rl.PlaySound(sound)
}

@(private = "file")
play_sound_enemy :: proc(sound: rl.Sound, clumpa, clumpb: Hexagon_Clump, volume := f32(1)) {
	mult := get_volume_mult(clumpa, clumpb)
	rl.SetSoundVolume(sound, volume * mult)
	rl.PlaySound(sound)
}

play_sound :: proc{
	play_sound_normal,
	play_sound_enemy,
}

@(private = "file")
get_volume_mult :: proc(a, b: Hexagon_Clump) -> f32 {
	distance := clump_distance(a, b)
	return max(0.4 - distance / 1000, 0)
}

load_sounds :: proc() {
	shoot = rl.LoadSound("audio/shoot.ogg")
	fire_spell = rl.LoadSound("audio/fire_spell.ogg")
	explosion = rl.LoadSound("audio/explosion.ogg")
	ui_confirm = rl.LoadSound("audio/ui_confirm.ogg")
	damaged = rl.LoadSound("audio/damaged.ogg")
	merge = rl.LoadSound("audio/merge.ogg")
	death = rl.LoadSound("audio/death.ogg")
	freeze = rl.LoadSound("audio/freeze.ogg")
}

unload_sounds :: proc() {
	rl.UnloadSound(shoot)
	rl.UnloadSound(fire_spell)
	rl.UnloadSound(explosion)
	rl.UnloadSound(ui_confirm)
	rl.UnloadSound(damaged)
	rl.UnloadSound(merge)
	rl.UnloadSound(death)
	rl.UnloadSound(freeze)
}