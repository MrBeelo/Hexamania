package main

import rl "vendor:raylib"

GameState :: enum { PLAYING, MAIN, PAUSED, FINISH, ANALYSIS }
game_state := GameState.MAIN
menus: [GameState]Menu
death_sequence_time_left := f32(0)

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
		NewButtonDef("PLAY", SCREEN_SIZE / 2, proc(){ 
			ResetGame()
			game_state = .PLAYING 
			player.can_shoot = false
		}),
	},
	draw = proc(buttons: []Button) {
		DrawMainMenuBackground()
		DrawMenuTitle("HEXAMANIA")
		DrawText(".io", {SCREEN_SIZE.x / 2 + 250, 80}, 32, spacing = 2)
		DrawText("Made by MrBeelo for the Raylib 6.x game jam!", {10, SCREEN_SIZE.y - 24 - 10}, 24, .QUICKSAND_LIGHT, spacing = 2)
		DrawText(VERSION, {SCREEN_SIZE.x - MeasureText(VERSION, 24, .QUICKSAND_LIGHT, 2).x - 10, SCREEN_SIZE.y - 24 - 10}, 
			24, .QUICKSAND_LIGHT, spacing = 2)
		
		for &button in buttons do DrawButton(button)
	},
)}

PausedMenu :: proc() -> Menu { return NewMenu(
	buttons = []Button{
		NewButtonDef("CONTINUE", SCREEN_SIZE / 2, proc(){ game_state = .PLAYING; player.can_shoot = false }),
		NewButtonDef("LEAVE", SCREEN_SIZE / 2 + {0, 100}, proc(){ game_state = .MAIN }),
	},
	draw = proc(buttons: []Button) {
		DrawMainMenuBackground()
		DrawMenuTitle("PAUSED")
		for &button in buttons do DrawButton(button)
	},
)}

FinishMenu :: proc() -> Menu { return NewMenu(
	buttons = []Button{
		NewButtonDef("PLAY AGAIN", SCREEN_SIZE / 2 + {-150, 250}, proc(){ ResetGame(); game_state = .PLAYING; player.can_shoot = false }, true),
		NewButtonDef("LEAVE", SCREEN_SIZE / 2 + {175, 250}, proc(){ game_state = .MAIN }, true),
	},
	update = proc(buttons: []Button) {
		if death_sequence_time_left <= 0 {
			for &button in buttons do UpdateButton(&button)
		}
	},
	draw = proc(buttons: []Button) {
		death_sequence_time_left -= rl.GetFrameTime()

		DrawMainMenuBackground()
		
		DrawMenuTitle("YOU DIED")

		time_survived_text := FloatToTimeStr(GetElapsedStopwatchTime(time_survived)) if death_sequence_time_left <= 7 else ""
		if death_sequence_time_left < 8 do DrawFinishStat("Time Survived: %s", 0, time_survived_text)

		kills_text := rl.TextFormat("%d", kills) if death_sequence_time_left <= 5 else ""
		if death_sequence_time_left < 6 do DrawFinishStat("Kills: %s", 1, kills_text)

		hexagons_text := rl.TextFormat("%d", len(player.hexagon_types) - 2) if death_sequence_time_left <= 3 else ""
		if death_sequence_time_left < 4 do DrawFinishStat("Hexagons Obtained: %s", 2, hexagons_text)
		
		if death_sequence_time_left <= 2 do DrawTextCenter("Your grade:", SCREEN_SIZE / 2 + {200, -150}, 32, spacing = 2)
		if death_sequence_time_left <= 1 do DrawTextCenter(GetGradeLetter(GetGradeScore()), SCREEN_SIZE / 2 + {200, -50}, 128)
				
		if death_sequence_time_left <= 0 do for &button in buttons do DrawButton(button)
	},
)}

AnalysisMenu :: proc() -> Menu { return NewMenu(
	buttons = []Button {
		NewButtonDef("BACK", SCREEN_SIZE / 2 + {0, 250}, proc(){ game_state = .PLAYING; player.can_shoot = false }, true),
	},
	draw = proc(buttons: []Button) {
		DrawMainMenuBackground()
		DrawMenuTitle("ANALYSIS")

		hexagon_type_amounts := GetHexagonTypeAmounts(player.clump)

		DrawAnalysisStat("RIFLE: Pellets shoot at %.0f px/s speed,\n dealing %.0f damage, with %.2f/s fire rate.", 
			0, GetRifleStats(hexagon_type_amounts))
		
		if HasSpell(player.clump, .HEALTH_PAD) do DrawAnalysisStat(
			"HEALTH PAD: Lasts for %.0f seconds,\n %.0f pixels long, and heals %.0f hp each second.", 
			1, GetHealthPadStats(hexagon_type_amounts))
		
		if HasSpell(player.clump, .ICE_BALL) do DrawAnalysisStat(
			"ICE BALL: Lasts for %.0f seconds,\n %.0f pixels long, freezes enemies for %.0f seconds.", 
			2, GetIceBallStats(hexagon_type_amounts))
		
		if HasSpell(player.clump, .FIREBALL) do DrawAnalysisStat(
			"FIREBALL: Lasts for %.0f seconds,\n %.0f pixels long, dealing %.0f damage every second.", 
			3, GetFireballStats(hexagon_type_amounts))
		
		if HasSpell(player.clump, .BLACK_HOLE) do DrawAnalysisStat(
			"BLACK HOLE: Lasts for %.0f seconds,\n with %.0f suction power, and %.0f pixels long.", 
			4, GetBlackHoleStats(hexagon_type_amounts))
		
		for &button in buttons do DrawButton(button)
	},
)}

StartDeathSequence :: proc() {
	StopStopwatch(&time_survived)
	game_state = .FINISH
	death_sequence_time_left = 10
	rl.PlayMusicStream(death_music)
}

GetGradeScore :: proc() -> int {
	grade := int(GetElapsedStopwatchTime(time_survived) / 50 + f32(killed_hexagons) * 3)
	if len(player.hexagon_types) == MAX_HEXAGONS do grade += 150
	return grade
}

GetGradeLetter :: proc(num: int) -> cstring {	
	switch {
	case num < 50: return "F"
	case num < 120: return "D"
	case num < 250: return "C"
	case num < 350: return "B"
	case num < 500: return "A"
	case: return "S"
	}
	
	return ""
}

ResetGame :: proc() {
	player = NewPlayer()
	clear(&enemies)
	clear(&pellets)
	clear(&hearts)
	clear(&world_powerups)
	killed_hexagons = 0
	
	StartStopwatch(&time_survived)
	session_playthroughs += 1

	powerup_message_time = 10
	upgrade_message_time = 10
	hexagon_found_time = 0
}

// Helper functions so that I dont have to rewrite the code again and again:

DrawMenuTitle :: proc(text: cstring) {
	DrawTextCenter(text, {SCREEN_SIZE.x / 2, 70}, 96, .QUICKSAND_HEAVY, border_info = {true, 3, rl.BLACK})
}

NewButtonDef :: proc(text: cstring, center: rl.Vector2, function: proc(), small := false) -> Button {
	return NewButton(text, center, function, 64 if !small else 48, .QUICKSAND_MEDIUM, {rl.WHITE, rl.YELLOW}, 5)
}

DrawFinishStat :: proc(text: cstring, index: int, args: ..any) {
	str := rl.TextFormat(text, ..args)
	pos := rl.Vector2{SCREEN_SIZE.x / 2 - 275, SCREEN_SIZE.y / 2 - 150 + f32(index) * 40}
	DrawText(str, pos, 32, spacing = 3)
}

DrawAnalysisStat :: proc(text: cstring, index: int, args: ..any) {
	str := rl.TextFormat(text, ..args)
	pos := rl.Vector2{SCREEN_SIZE.x / 2 - 300, SCREEN_SIZE.y / 2 - 150 + f32(index) * 50}
	count: i32
	strs := rl.TextSplit(str, '\n', &count)
	DrawText(strs[0], pos, 24, spacing = 3)
	DrawText(strs[1], pos + {0, 25}, 24, spacing = 3)
}