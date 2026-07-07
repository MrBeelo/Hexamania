package main

import "core:fmt"
import rl "vendor:raylib"
import "core:strings"

SCREEN_SIZE :: rl.Vector2{720, 720}
should_close := false

clump: HexagonClump
rot := f32(0)

log :: proc(str: string, args: ..any) { fmt.printfln(strings.concatenate({"GAME: ", str}), ..args) }

init :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(i32(SCREEN_SIZE.x), i32(SCREEN_SIZE.y), "Hexamania.io")
	LoadHexagons()

	clump = NewHexagonClump({.BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK,
		.BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK,
		.BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK,
		.BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK,
		.BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK,
		.BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK, .BLANK}, SCREEN_SIZE / 2, 0)
}

update :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	
	rl.ClearBackground(rl.WHITE)

	clump.rot += rl.GetFrameTime() * 100

	DrawHexagonClump(clump)
	rl.DrawCircleV(SCREEN_SIZE / 2, 5, rl.RED)

    free_all(context.temp_allocator)
}

close :: proc() { 
	UnloadHexagons()
	rl.CloseWindow() 
}