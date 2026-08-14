package main

import rl "raylib"

shoot, fire_spell, explosion, ui_confirm, damaged, merge: rl.Sound

PlaySound :: proc(sound: rl.Sound, volume := f32(1), pitch := f32(1)) {
	rl.SetSoundVolume(sound, volume)
	rl.SetSoundPitch(sound, pitch)
	rl.PlaySound(sound)
}

LoadSounds :: proc() {
	shoot = rl.LoadSound("audio/shoot.wav")
	fire_spell = rl.LoadSound("audio/fire_spell.wav")
	explosion = rl.LoadSound("audio/explosion.wav")
	ui_confirm = rl.LoadSound("audio/ui_confirm.wav")
	damaged = rl.LoadSound("audio/damaged.wav")
	merge = rl.LoadSound("audio/merge.wav")
}

UnloadSounds :: proc() {
	rl.UnloadSound(shoot)
	rl.UnloadSound(fire_spell)
	rl.UnloadSound(explosion)
	rl.UnloadSound(ui_confirm)
	rl.UnloadSound(damaged)
	rl.UnloadSound(merge)
}