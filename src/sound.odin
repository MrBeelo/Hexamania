package main

import rl "raylib"

shoot, fire_spell, explosion, ui_confirm, damaged, merge: rl.Sound

PlaySoundNormal :: proc(sound: rl.Sound, volume := f32(1)) {
	rl.SetSoundVolume(sound, volume)
	rl.PlaySound(sound)
}

PlaySoundEnemy :: proc(sound: rl.Sound, clumpa, clumpb: HexagonClump, volume := f32(1)) {
	mult := GetVolumeMult(clumpa, clumpb)
	rl.SetSoundVolume(sound, volume * mult)
	rl.PlaySound(sound)
}

PlaySound :: proc{
	PlaySoundNormal,
	PlaySoundEnemy,
}

GetVolumeMult :: proc(a, b: HexagonClump) -> f32 {
	distance := ClumpDistance(a, b)
	return max(0.4 - distance / 1000, 0)
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