package main

import "core:fmt"
import rl "raylib"
import "core:strings"

SCREEN_SIZE := rl.Vector2{720, 720} // It is a variable so it can be indexed (not planning to make the window resizable)
VERSION :: "1.2.5"
debug_on := false

player: Player

log :: proc(str: string, args: ..any) { fmt.printfln(strings.concatenate({"GAME: ", str}), ..args) }

init :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_HIGHDPI, .MSAA_4X_HINT})
	rl.InitWindow(i32(SCREEN_SIZE.x), i32(SCREEN_SIZE.y), "Hexamania.io")
	rl.SetExitKey(.NULL)
	rl.InitAudioDevice()
	SearchAndSetResourceDir("res")
	GuiLoadStyleHexamania()
	
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
	if Holding(.SPRINT) && rl.IsKeyPressed(.F3) do debug_on = !debug_on
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

		if debug_on do DrawDebug()
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