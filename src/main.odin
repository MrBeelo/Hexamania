package main

import "core:fmt"
import rl "vendor:raylib"
import "core:strings"

screen_size := rl.Vector2{720, 720}
should_close := false

player: Player

log :: proc(str: string, args: ..any) { fmt.printfln(strings.concatenate({"GAME: ", str}), ..args) }

init :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_HIGHDPI, .MSAA_4X_HINT})
	rl.InitWindow(i32(screen_size.x), i32(screen_size.y), "Hexamania.io")
	LoadHexagons()

	StartStopwatch(&time_survived)
	player = NewPlayer()
	append(&enemies, NewEnemy({.BLANK, .BLANK, .BLANK}, 100))
	append(&enemies, NewEnemy({.BLANK, .BLANK}, -100))
}

update :: proc() {
	UpdatePlayer(&player)
	UpdatePellets()
	UpdateHexagonHearts()
	UpdateEnemies()
	
	if rl.IsKeyPressed(.N) do AddHexagonToClump(&player.clump, .BLANK)
	if rl.IsKeyPressed(.K) do StopStopwatch(&time_survived)
	if rl.IsMouseButtonPressed(.LEFT) do PlayerFirePellet()
	
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(rl.LIGHTGRAY)

	rl.BeginMode2D(player.camera)
	
	DrawPlayer(&player)
	DrawPellets()
	DrawHexagonHearts()
	DrawEnemies()
	
	rl.EndMode2D()

	rl.DrawText(rl.TextFormat("pos: %.2f, %.2f", player.pos.x, player.pos.y), 10, 10, 32, rl.BLACK)
	rl.DrawText(rl.TextFormat("vel: %.2f, %.2f", player.vel.x, player.vel.y), 10, 50, 32, rl.BLACK)
	rl.DrawText(rl.TextFormat("speed: %d", PLAYER_SPEED), 10, 90, 32, rl.BLACK)
	rl.DrawText(rl.TextFormat("acc: %d", PLAYER_ACCELERATION), 10, 130, 32, rl.BLACK)
	rl.DrawText(rl.TextFormat("time survived: %f", GetElapsedStopwatchTime(time_survived)), 10, 170, 32, rl.BLACK)
	rl.DrawText(rl.TextFormat("points: %d", points), 10, 210, 32, rl.BLACK)
	rl.DrawText(rl.TextFormat("spr1: %v", player.spr.sprinting), 10, 250, 32, rl.BLACK)
	rl.DrawText(rl.TextFormat("spr2: %v", player.spr.sprint_secs), 10, 290, 32, rl.BLACK)
	rl.DrawText(rl.TextFormat("spr3: %v", player.spr.time_since_last_sprint), 10, 330, 32, rl.BLACK)

    free_all(context.temp_allocator)
}

close :: proc() { 
	UnloadHexagons()
	rl.CloseWindow() 
}