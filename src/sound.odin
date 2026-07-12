package main

import rl "vendor:raylib"

shoot, fire_spell, explosion, ui_confirm, damaged, merge: rl.Sound

LoadSounds :: proc() {
	shoot = rl.LoadSound("res/sound/shoot.wav")
	fire_spell = rl.LoadSound("res/sound/fire_spell.wav")
	explosion = rl.LoadSound("res/sound/explosion.wav")
	ui_confirm = rl.LoadSound("res/sound/ui_confirm.wav")
	damaged = rl.LoadSound("res/sound/damaged.wav")
	merge = rl.LoadSound("res/sound/merge.wav")
	
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