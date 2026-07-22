package main

import "core:fmt"
import rl "vendor:raylib"
import "core:strings"

SCREEN_SIZE := rl.Vector2{720, 720} // It is a variable so it can be indexed (not planning to make the window resizable)
DEBUG_ON :: false
VERSION :: "1.1.5"

player: Player

log :: proc(str: string, args: ..any) { fmt.printfln(strings.concatenate({"GAME: ", str}), ..args) }

init :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_HIGHDPI, .MSAA_4X_HINT})
	rl.InitWindow(i32(SCREEN_SIZE.x), i32(SCREEN_SIZE.y), "Hexamania.io")
	rl.SetExitKey(.KEY_NULL)
	rl.InitAudioDevice()
	
	LoadHexagons()
	LoadBackground()
	LoadPowerups()
	LoadFonts()
	LoadFace()
	LoadSpells()
	LoadUI()
	LoadSounds()
	LoadMusic()
	
	InitMenus()
	InitEnemies()
}

update :: proc() {
	ResetHexagonClumps()
	UpdateMenus()
	if game_state == .PLAYING {
		UpdatePlayer(&player)
		UpdatePellets()
		UpdateHexagonHearts()
		UpdateEnemies()
		UpdateWorldPowerups()
		UpdateSpells()
		UpdateToolbar()
		
		if rl.IsKeyPressed(.ESCAPE) do game_state = .PAUSED
		if rl.IsKeyPressed(.LEFT_CONTROL) do game_state = .ANALYSIS
	}

	UpdateMusic()
	
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(rl.DARKBLUE)

	if game_state == .PLAYING {
		rl.BeginMode2D(player.camera)

		DrawGameBackground()
		DrawSpellsBelow()
		DrawHexagonHearts()
		DrawWorldPowerups()
		DrawEnemies()
		DrawPlayer(&player)
		DrawPellets()
		DrawSpellsAbove()
		
		rl.EndMode2D()

		// HUD
		DrawPlayerHealthBar()
		DrawMap()
		DrawActiveSpellPreview()
		DrawSpellMenu()
		DrawBoundPowerups(player.bound_powerups)
		DrawToolbar()

		if DEBUG_ON {
			rl.DrawText(rl.TextFormat("pos: %.2f, %.2f", player.pos.x, player.pos.y), 10, 10, 32, rl.BLACK)
			rl.DrawText(rl.TextFormat("vel: %.2f, %.2f", player.vel.x, player.vel.y), 10, 50, 32, rl.BLACK)
			rl.DrawText(rl.TextFormat("speed: %.0f", GetPlayerSpeed(player)), 10, 90, 32, rl.BLACK)
			rl.DrawText(rl.TextFormat("acc: %d", PLAYER_ACCELERATION), 10, 130, 32, rl.BLACK)
			rl.DrawText(rl.TextFormat("time survived: %f", GetElapsedStopwatchTime(time_survived)), 10, 170, 32, rl.BLACK)
			rl.DrawText(rl.TextFormat("score: %d", killed_hexagons), 10, 210, 32, rl.BLACK)
			rl.DrawText(rl.TextFormat("fps: %d", rl.GetFPS()), 10, 250, 32, rl.BLACK)
			rl.DrawText(rl.TextFormat("enemies: %d", len(enemies)), 10, 290, 32, rl.BLACK)
			rl.DrawText(rl.TextFormat("powerups: %d", len(world_powerups)), 10, 330, 32, rl.BLACK)
		}
	}

	DrawMenus()

    free_all(context.temp_allocator)
}

close :: proc() { 
	UnloadHexagons()
	UnloadBackground()
	UnloadPowerups()
	UnloadFonts()
	UnloadFace()
	UnloadSpells()
	UnloadUI()
	UnloadSounds()
	UnloadMusic()

	rl.CloseAudioDevice()
	rl.CloseWindow() 
}