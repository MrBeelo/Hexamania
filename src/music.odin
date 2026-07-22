package main

import rl "vendor:raylib"

main_music, death_music: rl.Music
MAIN_MENU_LOOP_SECONDS :: 24

LoadMusic :: proc() {
	main_music = rl.LoadMusicStream("audio/main_music.mp3")
	death_music = rl.LoadMusicStream("audio/death_music.mp3")
	death_music.looping = false
}

UnloadMusic :: proc() {
	rl.UnloadMusicStream(main_music)
	rl.UnloadMusicStream(death_music)
}

UpdateMusic :: proc() {
	if rl.IsMusicStreamPlaying(main_music) do rl.UpdateMusicStream(main_music)
	if rl.IsMusicStreamPlaying(death_music) do rl.UpdateMusicStream(death_music)
	
	if game_state != .FINISH { 
		rl.SetMusicVolume(main_music, 1 if game_state == .PLAYING || game_state == .MAIN else 0.3)
		if !rl.IsMusicStreamPlaying(main_music) do rl.PlayMusicStream(main_music)
		if game_state == .MAIN && rl.GetMusicTimePlayed(main_music) >= MAIN_MENU_LOOP_SECONDS do rl.SeekMusicStream(main_music, 0)
		if rl.IsMusicStreamPlaying(death_music) do rl.StopMusicStream(death_music)
	} else {
		if rl.IsMusicStreamPlaying(main_music) do rl.StopMusicStream(main_music)
	}
}