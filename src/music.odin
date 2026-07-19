package main

import rl "vendor:raylib"

game_music, main_menu_music,death_music: rl.Music
should_play_death_music := false

LoadMusic :: proc() {
	game_music = rl.LoadMusicStream("res/music/game.mp3")
	main_menu_music = rl.LoadMusicStream("res/music/main_menu.mp3")
	death_music = rl.LoadMusicStream("res/music/death.mp3")
}

UnloadMusic :: proc() {
	rl.UnloadMusicStream(game_music)
	rl.UnloadMusicStream(main_menu_music)
	rl.UnloadMusicStream(death_music)
}

UpdateMusic :: proc() {
	if rl.IsMusicStreamPlaying(game_music) do rl.UpdateMusicStream(game_music)
	if rl.IsMusicStreamPlaying(main_menu_music) do rl.UpdateMusicStream(main_menu_music)
	if rl.IsMusicStreamPlaying(death_music) && should_play_death_music do rl.UpdateMusicStream(death_music)
	
	if game_state == .MAIN { 
		if !rl.IsMusicStreamPlaying(main_menu_music) do rl.PlayMusicStream(main_menu_music)
	} else {
		if rl.IsMusicStreamPlaying(main_menu_music) do rl.StopMusicStream(main_menu_music)
	}
	
	if game_state == .PLAYING || game_state == .PAUSED || game_state == .ANALYSIS { 
		rl.SetMusicVolume(game_music, 1 if game_state == .PLAYING else 0.3)
		if !rl.IsMusicStreamPlaying(game_music) do rl.PlayMusicStream(game_music)
	} else {
		if rl.IsMusicStreamPlaying(game_music) do rl.StopMusicStream(game_music)
	}
	
	if game_state != .FINISH && rl.IsMusicStreamPlaying(death_music) do rl.StopMusicStream(death_music)
}