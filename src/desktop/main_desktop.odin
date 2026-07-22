package desktop

import rl "vendor:raylib"
import game ".."

main :: proc() {
	game.init()
	for !rl.WindowShouldClose() do game.update()
	game.close()
}