package main

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"

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
		NewButtonDef("PLAY", screen_size / 2, proc(){ ResetGame(); game_state = .PLAYING; player.can_shoot = false }),
	},
	draw = proc(buttons: []Button) {
		DrawMainMenuBackground()
		DrawMenuTitle("HEXAMANIA")
		DrawText("Made by MrBeelo for the Raylib 6.x game jam!", {10, screen_size.y - 24 - 10}, 24, .QUICKSAND_LIGHT, spacing = 2)
		DrawText("0.8", {screen_size.x - 32 - 10, screen_size.y - 24 - 10}, 24, .QUICKSAND_LIGHT, spacing = 2)
		for &button in buttons do DrawButton(button)
	},
)}

PausedMenu :: proc() -> Menu { return NewMenu(
	buttons = []Button{
		NewButtonDef("CONTINUE", screen_size / 2, proc(){ game_state = .PLAYING; player.can_shoot = false }),
		NewButtonDef("LEAVE", screen_size / 2 + {0, 100}, proc(){ game_state = .MAIN }),
	},
	draw = proc(buttons: []Button) {
		DrawMainMenuBackground()
		DrawMenuTitle("PAUSED")
		for &button in buttons do DrawButton(button)
	},
)}

FinishMenu :: proc() -> Menu { return NewMenu(
	buttons = []Button{
		NewButtonDef("PLAY AGAIN", screen_size / 2 + {-150, 250}, proc(){ ResetGame(); game_state = .PLAYING; player.can_shoot = false }, true),
		NewButtonDef("LEAVE", screen_size / 2 + {150, 250}, proc(){ game_state = .MAIN }, true),
	},
	update = proc(buttons: []Button) {
		if death_sequence_time_left <= 0 {
			for &button in buttons do UpdateButton(&button)
			should_play_death_music = false
		}
	},
	draw = proc(buttons: []Button) {
		death_sequence_time_left -= rl.GetFrameTime()
	
		grade := int(GetElapsedStopwatchTime(time_survived) / 50 + f32(points) * 3)
		if len(player.hexagon_types) == MAX_HEXAGONS do grade += 150

		DrawMainMenuBackground()
		
		DrawMenuTitle("YOU DIED")
		
		if death_sequence_time_left > 7 && death_sequence_time_left < 8 {
			DrawFinishStat("Time Survived:", 0)
		} else if death_sequence_time_left <= 7 {
			DrawFinishStat("Time Survived: %s", 0, FloatToTimeStr(GetElapsedStopwatchTime(time_survived)))
		}
		
		if death_sequence_time_left > 5 && death_sequence_time_left < 6 {
			DrawFinishStat("Points:", 1)
		} else if death_sequence_time_left <= 5 {
			DrawFinishStat("Points: %d", 1, points)
		}
		
		if death_sequence_time_left > 3 && death_sequence_time_left < 4 {
			DrawFinishStat("Hexagons Obtained:", 2)
		} else if death_sequence_time_left <= 3 {
			DrawFinishStat("Hexagons Obtained: %d", 2, len(player.hexagon_types) - 1)
		}
		
		if death_sequence_time_left <= 2 {
			DrawTextCenter("Your grade:", screen_size / 2 + {175, -150}, 32, spacing = 2)
		}
		
		if death_sequence_time_left <= 1 {
			DrawTextCenter(GetGrade(grade)[0], screen_size / 2 + {175, -50}, 128)
		}
				
		if death_sequence_time_left <= 0 do for &button in buttons do DrawButton(button)
	},
)}

AnalysisMenu :: proc() -> Menu { return NewMenu(
	buttons = []Button {
		NewButtonDef("BACK", screen_size / 2 + {0, 250}, proc(){ game_state = .PLAYING; player.can_shoot = false }, true),
	},
	draw = proc(buttons: []Button) {
		DrawMainMenuBackground()
		DrawMenuTitle("ANALYSIS")

		hexagon_type_amounts := GetHexagonTypeAmounts(player.clump)

		DrawAnalysisStat("RIFLE: Pellets shoot at %.0f px/s speed,\n dealing %.0f damage, with %.2f/s fire rate.", 0, GetRifleStats(hexagon_type_amounts))
		if HasSpell(player.clump, .HEALTH_PAD) do DrawAnalysisStat("HEALTH PAD: Lasts for %.0f seconds,\n %.0f pixels long, and heals %.0f hp each second.", 1, GetHealthPadStats(hexagon_type_amounts))
		if HasSpell(player.clump, .ICE_BALL) do DrawAnalysisStat("ICE BALL: Lasts for %.0f seconds,\n %.0f pixels long, freezes enemies for %.0f seconds.", 2, GetIceBallStats(hexagon_type_amounts))
		if HasSpell(player.clump, .FIREBALL) do DrawAnalysisStat("FIREBALL: Lasts for %.0f seconds,\n %.0f pixels long, dealing %.0f damage every second.", 3, GetFireballStats(hexagon_type_amounts))
		if HasSpell(player.clump, .BLACK_HOLE) do DrawAnalysisStat("BLACK HOLE: Lasts for %.0f seconds,\n with %.0f suction power, and %.0f pixels long.", 4, GetBlackHoleStats(hexagon_type_amounts))
		
		for &button in buttons do DrawButton(button)
	},
)}

StartDeathSequence :: proc() {
	StopStopwatch(&time_survived)
	game_state = .FINISH
	death_sequence_time_left = 10
	should_play_death_music = true
	rl.PlayMusicStream(death_music)
}

GetGrade :: proc(num: int) -> [2]string {	
	switch {
	case num < 50: return {"F", "Yeah, that was pretty bad...\n But it's okay! Try again and you'll\n get better!"}
	case num < 120: return {"D", "Not good, but not terrible either.\n Try getting more kills to maximize\n your hexahearts and your score!"}
	case num < 250: return {"C", "You did average. Not bad, but you\n have potential! Staying alive for longer\n and getting more kills will boost\n your score to great heights!"}
	case num < 350: return {"B", "Okay, that was actually pretty good!\n Keep going like this and you'll have\n secured the win in no time!"}
	case num < 500: return {"A", "Wow! Amazing performace!\n Only thing that stopped you from getting an S rank\n is defeating every other clump.\n You got this!"}
	}
	
	return {"S", "Great job!! And thanks for playing my game\n <3"}
}

ResetGame :: proc() {
	player = NewPlayer()
	clear(&enemies)
	clear(&pellets)
	clear(&hearts)
	clear(&world_powerups)
	points = 0
	StartStopwatch(&time_survived)
	session_playthroughs += 1
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
	pos := rl.Vector2{screen_size.x / 2 - 300, screen_size.y / 2 - 150 + f32(index) * 40}
	DrawText(str, pos, 32, spacing = 3)
}

DrawAnalysisStat :: proc(text: string, index: int, args: ..any) {
	str := string(fmt.ctprintf(text, ..args))
	pos := rl.Vector2{screen_size.x / 2 - 300, screen_size.y / 2 - 150 + f32(index) * 50}
	strs := strings.split(str, "\n")
	assert(len(strs) == 2)
	DrawText(strs[0], pos, 24, spacing = 3)
	DrawText(strs[1], pos + {0, 25}, 24, spacing = 3)
}