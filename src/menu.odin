package main

import rl "vendor:raylib"
import "core:fmt"

GameState :: enum { PLAYING, MAIN, PAUSED, FINISH, }
game_state := GameState.MAIN
menus: [GameState]Menu

Menu :: struct {
	buttons: []Button,
	update: proc(buttons: []Button),
	draw: proc(buttons: []Button),
}

NewMenu :: proc(
	buttons := []Button{},
	update := proc(buttons: []Button) { for &button in buttons do UpdateButton(&button) },
	draw := proc(buttons: []Button) { for &button in buttons do DrawButton(button) },
) -> Menu {
	btns := make([]Button, len(buttons))
	copy(btns, buttons)
	return {btns, update, draw} 
}

InitMenus :: proc() {
	menus = [GameState]Menu {
		.PLAYING = NewMenu(),
		.MAIN = MainMenu(),
		.PAUSED = PausedMenu(),
		.FINISH = FinishMenu(),
	}
}

UpdateMenus :: proc() {
	if game_state != .PLAYING do menus[game_state].update(menus[game_state].buttons)
}

DrawMenus :: proc() {
	if game_state != .PLAYING do menus[game_state].draw(menus[game_state].buttons)
}

MainMenu :: proc() -> Menu { return NewMenu(
	buttons = []Button{
		NewButtonDef("PLAY", screen_size / 2, proc(){ ResetGame(); game_state = .PLAYING }),
	},
	draw = proc(buttons: []Button) {
		DrawMenuTitle("HEXAMANIA")
		DrawText("Made by MrBeelo for the Raylib 6.x game jam!", {10, screen_size.y - 24 - 10}, 24, .QUICKSAND_LIGHT, spacing = 2)
		for &button in buttons do DrawButton(button)
	},
)}

PausedMenu :: proc() -> Menu { return NewMenu(
	buttons = []Button{
		NewButtonDef("CONTINUE", screen_size / 2, proc(){ game_state = .PLAYING }),
		NewButtonDef("LEAVE", screen_size / 2 + {0, 100}, proc(){ game_state = .MAIN }),
	},
	draw = proc(buttons: []Button) {
		DrawMenuTitle("PAUSED")
		for &button in buttons do DrawButton(button)
	},
)}

FinishMenu :: proc() -> Menu { return NewMenu(
	buttons = []Button{
		NewButtonDef("PLAY AGAIN", screen_size / 2 + {-150, 250}, proc(){ ResetGame(); game_state = .PLAYING }, true),
		NewButtonDef("RETURN", screen_size / 2 + {150, 250}, proc(){ game_state = .MAIN }, true),
	},
	draw = proc(buttons: []Button) {
		has_won := player.health > 0

		grade := int(GetElapsedStopwatchTime(time_survived) / 70 + f32(points) * 3)
		if len(player.hexagon_types) == MAX_HEXAGONS do grade += 300
		
		DrawMenuTitle("YOU WIN" if has_won else "YOU DIED")
		
		DrawStat("Time Survived: %s", 0, FloatToTimeStr(GetElapsedStopwatchTime(time_survived)))
		DrawStat("Points: %d", 1, points)
		DrawStat("Hexahearts: %d", 2, len(player.hexagon_types) - 1)
		DrawStat("Grade: %s (%d)", 3, GetGrade(grade, has_won)[0], grade)
		
		for &button in buttons do DrawButton(button)
	},
)}

GetGrade :: proc(num: int, has_won := false) -> [2]string {
	if has_won do return {"S", "You won. What did you expect?\n Great job!! And thanks for playing my game\n <3"}
	
	switch {
	case num < 100: return {"F", "Yeah, that was pretty bad...\n But it's okay! Try again and you'll\n get better!"}
	case num < 200: return {"D", "Not good, but not terrible either.\n Try getting more kills to maximize\n your hexahearts and your score!"}
	case num < 300: return {"C", "You did average. Not bad, but you\n have potential! Staying alive for longer\n and getting more kills will boost\n your score to great heights!"}
	case num < 400: return {"B", "Okay, that was actually pretty good!\n Keep going like this and you'll have\n secured the win in no time!"}
	case num < 500: return {"A", "Wow! Amazing performace!\n Only thing that stopped you from getting an S rank\n is defeating every other clump.\n You got this!"}
	}
	
	return {}
}

ResetGame :: proc() {
	player = NewPlayer()
	clear(&enemies)
	clear(&pellets)
	clear(&hearts)
	clear(&world_powerups)
	points = 0
	StartStopwatch(&time_survived) // NOTE: Stop this when the player dies

	// NOTE: Temporary, these should spawn naturally
	append(&enemies, NewEnemy({.BLANK, .BLANK, .BLANK}, 100))
	append(&enemies, NewEnemy({.BLANK, .BLANK}, -100))
	ThrowRandomWorldPowerup(200)
}

// Helper functions so that I dont have to rewrite the code again and again:

DrawMenuTitle :: proc(text: string) {
	DrawTextCenter(text, {screen_size.x / 2, 70}, 96, .QUICKSAND_HEAVY, border_info = {true, 3, rl.BLACK})
}

NewButtonDef :: proc(text: string, center: rl.Vector2, function: proc(), small := false) -> Button {
	return NewButton(text, center, function, 64 if !small else 48, .QUICKSAND_MEDIUM, {rl.WHITE, rl.YELLOW}, 5)
}

DrawStat :: proc(text: string, index: int, args: ..any) {
	str := string(fmt.ctprintf(text, ..args))
	pos := rl.Vector2{screen_size.x / 2 - 300, screen_size.y / 2 - 200 + f32(index) * 40}
	DrawText(str, pos, 32, spacing = 3)
}