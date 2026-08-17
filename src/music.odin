package main

import rl "raylib"

main_music, death_music: rl.Music
MAIN_MENU_LOOP_SECONDS :: 24
@(rodata) MUSIC_VOLUMES := [2]f32{0.7, 0.2} // active, inactive

load_music :: proc() {
	main_music = rl.LoadMusicStream("audio/main_music.mp3")
	death_music = rl.LoadMusicStream("audio/death_music.mp3")
	death_music.looping = false
	rl.SetMusicVolume(death_music, MUSIC_VOLUMES[0])
}

unload_music :: proc() {
	rl.UnloadMusicStream(main_music)
	rl.UnloadMusicStream(death_music)
}

update_music :: proc() {
	if rl.IsMusicStreamPlaying(main_music) do rl.UpdateMusicStream(main_music)
	if rl.IsMusicStreamPlaying(death_music) do rl.UpdateMusicStream(death_music)
	
	if game_state != .DEAD { 
		rl.SetMusicVolume(main_music, MUSIC_VOLUMES[0] if game_state == .PLAYING || game_state == .MAIN else MUSIC_VOLUMES[1])
		if !rl.IsMusicStreamPlaying(main_music) do rl.PlayMusicStream(main_music)
		if game_state == .MAIN && rl.GetMusicTimePlayed(main_music) >= MAIN_MENU_LOOP_SECONDS do rl.SeekMusicStream(main_music, 0)
		if rl.IsMusicStreamPlaying(death_music) do rl.StopMusicStream(death_music)
	} else {
		if rl.IsMusicStreamPlaying(main_music) do rl.StopMusicStream(main_music)
	}
}