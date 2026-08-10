package desktop

import rl "../raylib"
import game ".."

main :: proc() {
	context.allocator = heap_allocator()
	game.init()
	for !rl.WindowShouldClose() do game.update()
	game.close()
}