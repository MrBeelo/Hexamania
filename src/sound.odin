package main

import rl "vendor:raylib"

shoot, fire_spell, explosion, ui_confirm: rl.Sound

LoadSounds :: proc() {
	shoot = rl.LoadSound("res/sound/shoot.wav")
	fire_spell = rl.LoadSound("res/sound/fire_spell.wav")
	explosion = rl.LoadSound("res/sound/explosion.wav")
	ui_confirm = rl.LoadSound("res/sound/ui_confirm.wav")
}

UnloadSounds :: proc() {
	rl.UnloadSound(shoot)
	rl.UnloadSound(fire_spell)
	rl.UnloadSound(explosion)
	rl.UnloadSound(ui_confirm)
}