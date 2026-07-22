package main

import rl "vendor:raylib"

shoot, fire_spell, explosion, ui_confirm, damaged, merge: rl.Sound

LoadSounds :: proc() {
	shoot = rl.LoadSound("audio/shoot.wav")
	fire_spell = rl.LoadSound("audio/fire_spell.wav")
	explosion = rl.LoadSound("audio/explosion.wav")
	ui_confirm = rl.LoadSound("audio/ui_confirm.wav")
	damaged = rl.LoadSound("audio/damaged.wav")
	merge = rl.LoadSound("audio/merge.wav")
	
	rl.SetSoundVolume(merge, 0.7)
}

UnloadSounds :: proc() {
	rl.UnloadSound(shoot)
	rl.UnloadSound(fire_spell)
	rl.UnloadSound(explosion)
	rl.UnloadSound(ui_confirm)
	rl.UnloadSound(damaged)
	rl.UnloadSound(merge)
}