package main

import rl "vendor:raylib"
import "core:fmt"

GameState :: enum { PLAYING, MAIN, PAUSED, FINISH, ANALYSIS }
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
		.ANALYSIS = AnalysisMenu(),
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
		grade := int(GetElapsedStopwatchTime(time_survived) / 80 + f32(points) * 3)
		if len(player.hexagon_types) == MAX_HEXAGONS do grade += 150
		
		DrawMenuTitle("YOU DIED")
		
		DrawFinishStat("Time Survived: %s", 0, FloatToTimeStr(GetElapsedStopwatchTime(time_survived)))
		DrawFinishStat("Points: %d", 1, points)
		DrawFinishStat("Hexahearts: %d", 2, len(player.hexagon_types) - 1)
		DrawFinishStat("Grade: %s (%d)", 3, GetGrade(grade)[0], grade)
		
		for &button in buttons do DrawButton(button)
	},
)}

AnalysisMenu :: proc() -> Menu { return NewMenu(
	buttons = []Button {
		NewButtonDef("BACK", screen_size / 2 + {0, 250}, proc(){ game_state = .PLAYING }, true),
	},
	draw = proc(buttons: []Button) {
		DrawMenuTitle("ANALYSIS")

		hexagon_type_amounts := GetHexagonTypeAmounts(player.clump)

		DrawAnalysisStat("RIFLE: %.0f px/s, %.0f dmg, %.2f f.r.", 0, GetRifleStats(hexagon_type_amounts))
		if HasSpell(player.clump, .HEALTH_PAD) do DrawAnalysisStat("HEALTH PAD: %.0f s, %.0f px, %.0f hp", 1, GetHealthPadStats(hexagon_type_amounts))
		if HasSpell(player.clump, .ICE_BALL) do DrawAnalysisStat("ICE BALL: %.0f s, %.0f px, %.0f s", 2, GetIceBallStats(hexagon_type_amounts))
		if HasSpell(player.clump, .FIREBALL) do DrawAnalysisStat("FIREBALL: %.0f s, %.0f px, %.0f dmg", 3, GetFireballStats(hexagon_type_amounts))
		if HasSpell(player.clump, .BLACK_HOLE) do DrawAnalysisStat("BLACK HOLE: %.0f s, %.0f s.p., %.0f px", 4, GetBlackHoleStats(hexagon_type_amounts))
		
		for &button in buttons do DrawButton(button)
	},
)}

GetGrade :: proc(num: int) -> [2]string {	
	switch {
	case num < 100: return {"F", "Yeah, that was pretty bad...\n But it's okay! Try again and you'll\n get better!"}
	case num < 200: return {"D", "Not good, but not terrible either.\n Try getting more kills to maximize\n your hexahearts and your score!"}
	case num < 300: return {"C", "You did average. Not bad, but you\n have potential! Staying alive for longer\n and getting more kills will boost\n your score to great heights!"}
	case num < 400: return {"B", "Okay, that was actually pretty good!\n Keep going like this and you'll have\n secured the win in no time!"}
	case num < 500: return {"A", "Wow! Amazing performace!\n Only thing that stopped you from getting an S rank\n is defeating every other clump.\n You got this!"}
	case num < 600: return {"S", "Great job!! And thanks for playing my game\n <3"}
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
	StartStopwatch(&time_survived)
}

// Helper functions so that I dont have to rewrite the code again and again:

DrawMenuTitle :: proc(text: string) {
	DrawTextCenter(text, {screen_size.x / 2, 70}, 96, .QUICKSAND_HEAVY, border_info = {true, 3, rl.BLACK})
}

NewButtonDef :: proc(text: string, center: rl.Vector2, function: proc(), small := false) -> Button {
	return NewButton(text, center, function, 64 if !small else 48, .QUICKSAND_MEDIUM, {rl.WHITE, rl.YELLOW}, 5)
}

DrawFinishStat :: proc(text: string, index: int, args: ..any) {
	str := string(fmt.ctprintf(text, ..args))
	pos := rl.Vector2{screen_size.x / 2 - 300, screen_size.y / 2 - 200 + f32(index) * 40}
	DrawText(str, pos, 32, spacing = 3)
}

DrawAnalysisStat :: proc(text: string, index: int, args: ..any) {
	str := string(fmt.ctprintf(text, ..args))
	pos := rl.Vector2{screen_size.x / 2 - 300, screen_size.y / 2 - 150 + f32(index) * 50}
	DrawText(str, pos, 32, spacing = 3)
}