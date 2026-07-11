package main

import "core:fmt"
import rl "vendor:raylib"
import "core:strings"

screen_size := rl.Vector2{720, 720}
should_close := false
debug_on := true

player: Player

log :: proc(str: string, args: ..any) { fmt.printfln(strings.concatenate({"GAME: ", str}), ..args) }

init :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_HIGHDPI, .MSAA_4X_HINT})
	rl.InitWindow(i32(screen_size.x), i32(screen_size.y), "Hexamania.io")
	rl.SetExitKey(.KEY_NULL)
	rl.InitAudioDevice()
	
	LoadHexagons()
	LoadBackground()
	LoadPowerups()
	LoadFonts()
	LoadShaders()
	
	InitMenus()
	InitEnemies()
}

update :: proc() {
	UpdateMenus()
	if game_state == .PLAYING {
		UpdatePlayer(&player)
		UpdatePellets()
		UpdateHexagonHearts()
		UpdateEnemies()
		UpdateWorldPowerups()
		UpdateSpells()
		if rl.IsKeyPressed(.ESCAPE) do game_state = .PAUSED
		if rl.IsKeyPressed(.LEFT_CONTROL) do game_state = .ANALYSIS
	}

	if rl.IsKeyPressed(.F3) do debug_on = !debug_on
	if rl.IsKeyPressed(.N) do AddHexagonToClump(&player.clump, .RIFLE)
	
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(rl.DARKBLUE)

	DrawMenus()
	if game_state == .PLAYING {
		rl.BeginMode2D(player.camera)

		DrawBackground()
		DrawSpellsBelow()
		DrawHexagonHearts()
		DrawWorldPowerups()
		DrawPlayer(&player)
		DrawEnemies()
		DrawPellets()
		DrawSpellsAbove()
		
		rl.EndMode2D()

		// HUD
		DrawPlayerHealthBar()
		DrawMap()
		DrawActiveSpellPreview()
		DrawSpellMenu()

		if debug_on {
			rl.DrawText(rl.TextFormat("pos: %.2f, %.2f", player.pos.x, player.pos.y), 10, 10, 32, rl.BLACK)
			rl.DrawText(rl.TextFormat("vel: %.2f, %.2f", player.vel.x, player.vel.y), 10, 50, 32, rl.BLACK)
			rl.DrawText(rl.TextFormat("speed: %.0f", GetPlayerSpeed(player)), 10, 90, 32, rl.BLACK)
			rl.DrawText(rl.TextFormat("acc: %d", PLAYER_ACCELERATION), 10, 130, 32, rl.BLACK)
			rl.DrawText(rl.TextFormat("time survived: %f", GetElapsedStopwatchTime(time_survived)), 10, 170, 32, rl.BLACK)
			rl.DrawText(rl.TextFormat("points: %d", points), 10, 210, 32, rl.BLACK)
			rl.DrawText(rl.TextFormat("fps: %d", rl.GetFPS()), 10, 250, 32, rl.BLACK)
			rl.DrawText(rl.TextFormat("enemies: %d", len(enemies)), 10, 290, 32, rl.BLACK)
			rl.DrawText(rl.TextFormat("powerups: %d", len(world_powerups)), 10, 330, 32, rl.BLACK)
		}
	}

    free_all(context.temp_allocator)
}

close :: proc() { 
	UnloadHexagons()
	UnloadBackground()
	UnloadPowerups()
	UnloadFonts()
	UnloadShaders()

	rl.CloseAudioDevice()
	rl.CloseWindow() 
}