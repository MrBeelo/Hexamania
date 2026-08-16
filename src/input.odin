package main

import rl "raylib"

Game_Button :: enum { UP, DOWN, LEFT, RIGHT, HORIZ, VERT, SPRINT }

pressed :: proc(button: Game_Button) -> bool {
	switch button {
	case .UP: return rl.IsKeyPressed(.W) || rl.IsKeyPressed(.UP)
	case .DOWN: return rl.IsKeyPressed(.S) || rl.IsKeyPressed(.DOWN)
	case .LEFT: return rl.IsKeyPressed(.A) || rl.IsKeyPressed(.LEFT)
	case .RIGHT: return rl.IsKeyPressed(.D) || rl.IsKeyPressed(.RIGHT)
	case .HORIZ: return pressed(.LEFT) || pressed(.RIGHT)
	case .VERT: return pressed(.UP) || pressed(.DOWN)
	case .SPRINT: return rl.IsKeyPressed(.LEFT_SHIFT)
	}

	return false
}

holding :: proc(button: Game_Button) -> bool {
	switch button {
	case .UP: return rl.IsKeyDown(.W) || rl.IsKeyDown(.UP)
	case .DOWN: return rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN)
	case .LEFT: return rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT)
	case .RIGHT: return rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT)
	case .HORIZ: return holding(.LEFT) || holding(.RIGHT)
	case .VERT: return holding(.UP) || holding(.DOWN)
	case .SPRINT: return rl.IsKeyDown(.LEFT_SHIFT)
	}

	return false
}