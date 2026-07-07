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

	player = NewPlayer()
}

update :: proc() {
	UpdatePlayer(&player)
	if rl.IsKeyPressed(.N) do AddHexagonToClump(&player.clump, .BLANK)
	
	rl.BeginDrawing()
	defer rl.EndDrawing()
	
	rl.ClearBackground(rl.WHITE)

	rl.BeginMode2D(player.camera)
	
	rl.DrawCircleV(0, 2, rl.RED)
	DrawPlayer(&player)
	
	rl.EndMode2D()

	rl.DrawText(rl.TextFormat("pos: %.2f, %.2f", player.pos.x, player.pos.y), 10, 10, 32, rl.BLACK)
	rl.DrawText(rl.TextFormat("vel: %.2f, %.2f", player.vel.x, player.vel.y), 10, 50, 32, rl.BLACK)
	rl.DrawText(rl.TextFormat("speed: %d", SPEED), 10, 90, 32, rl.BLACK)
	rl.DrawText(rl.TextFormat("acc: %d", ACCELERATION), 10, 130, 32, rl.BLACK)

    free_all(context.temp_allocator)
}

close :: proc() { 
	UnloadHexagons()
	rl.CloseWindow() 
}