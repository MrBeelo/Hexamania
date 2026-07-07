package main

import rl "vendor:raylib"

Direction :: enum { UP, DOWN, LEFT, RIGHT, HORIZ, VERT }

Pressed :: proc(dir: Direction) -> bool {
	switch dir {
	case .UP: return rl.IsKeyPressed(.W) || rl.IsKeyPressed(.UP)
	case .DOWN: return rl.IsKeyPressed(.S) || rl.IsKeyPressed(.DOWN)
	case .LEFT: return rl.IsKeyPressed(.A) || rl.IsKeyPressed(.LEFT)
	case .RIGHT: return rl.IsKeyPressed(.D) || rl.IsKeyPressed(.RIGHT)
	case .HORIZ: return Pressed(.LEFT) || Pressed(.RIGHT)
	case .VERT: return Pressed(.UP) || Pressed(.DOWN)
	}

	return false
}

Holding :: proc(dir: Direction) -> bool {
	switch dir {
	case .UP: return rl.IsKeyDown(.W) || rl.IsKeyDown(.UP)
	case .DOWN: return rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN)
	case .LEFT: return rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT)
	case .RIGHT: return rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT)
	case .HORIZ: return Holding(.LEFT) || Holding(.RIGHT)
	case .VERT: return Holding(.UP) || Holding(.DOWN)
	}

	return false
}