package main

import "core:fmt"
import rl "raylib"
import "core:strings"

@(rodata) SCREEN_SIZE := rl.Vector2{720, 720} // It is a variable so it can be indexed (not planning to make the window resizable)
VERSION :: "1.3"
debug_on := false

player: Player

log :: proc(str: string, args: ..any) { fmt.printfln(strings.concatenate({"GAME: ", str}), ..args) }

init :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_HIGHDPI, .MSAA_4X_HINT})
	rl.InitWindow(i32(SCREEN_SIZE.x), i32(SCREEN_SIZE.y), "Hexamania.io")
	rl.SetExitKey(.NULL)
	rl.InitAudioDevice()
	search_and_set_resource_dir("res")
	load_style()
	
	load_hexagons()
	load_background()
	load_powerups()
	load_fonts()
	load_face()
	load_spells()
	load_gui()
	load_sounds()
	load_music()
	
	init_menus()
	init_enemies()
}

update :: proc() {
	if holding(.SPRINT) && rl.IsKeyPressed(.F3) do debug_on = !debug_on
	reset_clumps()
	update_menus()
	if game_state == .PLAYING {
		update_player(&player)
		update_pellets()
		update_hearts()
		update_enemies()
		update_world_powerups()
		update_spells()
		update_toolbar()
		
		if rl.IsKeyPressed(.ESCAPE) do game_state = .PAUSED
		if rl.IsKeyPressed(.LEFT_CONTROL) do game_state = .ANALYSIS
	}

	update_music()
	
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(rl.DARKBLUE)

	if game_state == .PLAYING {
		rl.BeginMode2D(player.camera)

		draw_game_background()
		draw_spells_bottom_layer()
		draw_hearts()
		draw_world_powerups()
		draw_enemies()
		draw_player(&player)
		draw_pellets()
		draw_spells_top_layer()
		
		rl.EndMode2D()

		// HUD
		draw_health_bar()
		draw_map()
		draw_active_spell_preview()
		draw_spell_menu()
		draw_bound_powerups(player.bound_powerups)
		draw_toolbar()

		if debug_on do draw_debug()
	}

	draw_menus()

    free_all(context.temp_allocator)
}

close :: proc() { 
	unload_hexagons()
	unload_background()
	unload_powerups()
	unload_fonts()
	unload_face()
	unload_spells()
	unload_gui()
	unload_sounds()
	unload_music()

	rl.CloseAudioDevice()
	rl.CloseWindow() 
}