package main

import rl "raylib"

Game_State :: enum { PLAYING, MAIN, PAUSED, DEAD, ANALYSIS }
game_state := Game_State.MAIN
menus: [Game_State]Menu
death_sequence_time_left := f32(0)

Menu :: struct {
	buttons: []Button,
	update: proc(buttons: []Button),
	draw: proc(buttons: []Button),
}

new_menu :: proc(
	buttons := []Button{},
	update := proc(buttons: []Button) { for &button in buttons do update_button(&button) },
	draw := proc(buttons: []Button) { for &button in buttons do draw_button(button) },
) -> Menu {
	btns := make([]Button, len(buttons))
	copy(btns, buttons)
	return {btns, update, draw} 
}

init_menus :: proc() {
	menus = [Game_State]Menu {
		.PLAYING = new_menu(),
		.MAIN = main_menu(),
		.PAUSED = paused_menu(),
		.DEAD = dead_menu(),
		.ANALYSIS = analysis_menu(),
	}
}

update_menus :: proc() {
	if game_state != .PLAYING do menus[game_state].update(menus[game_state].buttons)
}

draw_menus :: proc() {
	if game_state != .PLAYING do menus[game_state].draw(menus[game_state].buttons)
}

@(private = "file")
main_menu :: proc() -> Menu { return new_menu(
	buttons = []Button{
		new_button_def("PLAY", SCREEN_SIZE / 2, proc(){ 
			reset_game()
			game_state = .PLAYING 
			player.can_shoot = false
		}),
	},
	draw = proc(buttons: []Button) {
		draw_main_menu_background()
		draw_menu_title("HEXAMANIA")
		draw_text(".io", {SCREEN_SIZE.x / 2 + 250, 80}, 32, spacing = 2)
		draw_text("Made by MrBeelo for the Raylib 6.x game jam!", {10, SCREEN_SIZE.y - 24 - 10}, 24, .QUICKSAND_LIGHT, spacing = 2)
		draw_text(VERSION, {SCREEN_SIZE.x - measure_text(VERSION, 24, .QUICKSAND_LIGHT, 2).x - 10, SCREEN_SIZE.y - 24 - 10}, 
			24, .QUICKSAND_LIGHT, spacing = 2)
		
		for &button in buttons do draw_button(button)
	},
)}

@(private = "file")
paused_menu :: proc() -> Menu { return new_menu(
	buttons = []Button{
		new_button_def("CONTINUE", SCREEN_SIZE / 2, proc(){ game_state = .PLAYING; player.can_shoot = false }),
		new_button_def("LEAVE", SCREEN_SIZE / 2 + {0, 100}, proc(){ game_state = .MAIN }),
	},
	draw = proc(buttons: []Button) {
		draw_main_menu_background()
		draw_menu_title("PAUSED")
		for &button in buttons do draw_button(button)
	},
)}

@(private = "file")
dead_menu :: proc() -> Menu { return new_menu(
	buttons = []Button{
		new_button_def("PLAY AGAIN", SCREEN_SIZE / 2 + {-150, 250}, proc(){ reset_game(); game_state = .PLAYING; player.can_shoot = false }, true),
		new_button_def("LEAVE", SCREEN_SIZE / 2 + {175, 250}, proc(){ game_state = .MAIN }, true),
	},
	update = proc(buttons: []Button) {
		if death_sequence_time_left <= 0 {
			for &button in buttons do update_button(&button)
		}
	},
	draw = proc(buttons: []Button) {
		death_sequence_time_left -= rl.GetFrameTime()

		draw_main_menu_background()
		
		draw_menu_title("YOU DIED")

		time_survived_text := float_to_time_str(get_elapsed_stopwatch_time(time_survived)) if death_sequence_time_left <= 7 else ""
		if death_sequence_time_left < 8 do draw_dead_stat("Time Survived: %s", 0, time_survived_text)

		kills_text := rl.TextFormat("%d", kills) if death_sequence_time_left <= 5 else ""
		if death_sequence_time_left < 6 do draw_dead_stat("Kills: %s", 1, kills_text)

		hexagons_text := rl.TextFormat("%d", len(player.hexagon_types) - 2) if death_sequence_time_left <= 3 else ""
		if death_sequence_time_left < 4 do draw_dead_stat("Hexagons Obtained: %s", 2, hexagons_text)
		
		if death_sequence_time_left <= 2 do draw_text_center("Your grade:", SCREEN_SIZE / 2 + {200, -150}, 32, spacing = 2)
		if death_sequence_time_left <= 1 do draw_text_center(get_grade_letter(get_grade_score()), SCREEN_SIZE / 2 + {200, -50}, 128)
				
		if death_sequence_time_left <= 0 do for &button in buttons do draw_button(button)
	},
)}

@(private = "file")
analysis_menu :: proc() -> Menu { return new_menu(
	buttons = []Button {
		new_button_def("BACK", SCREEN_SIZE / 2 + {0, 250}, proc(){ game_state = .PLAYING; player.can_shoot = false }, true),
	},
	draw = proc(buttons: []Button) {
		draw_main_menu_background()
		draw_menu_title("ANALYSIS")

		hexagon_type_amounts := get_hexagon_type_amounts(player.clump)

		draw_analysis_stat("RIFLE: Pellets shoot at %.0f px/s speed,\n dealing %.0f damage, with %.2f/s fire rate.", 
			0, get_rifle_stats(hexagon_type_amounts))
		
		if has_spell(player.clump, .HEALTH_PAD) do draw_analysis_stat(
			"HEALTH PAD: Lasts for %.0f seconds,\n %.0f pixels long, and heals %.0f hp each second.", 
			1, get_health_pad_stats(hexagon_type_amounts))
		
		if has_spell(player.clump, .ICE_BALL) do draw_analysis_stat(
			"ICE BALL: Lasts for %.0f seconds,\n %.0f pixels long, freezes enemies for %.0f seconds.", 
			2, get_ice_ball_stats(hexagon_type_amounts))
		
		if has_spell(player.clump, .FIREBALL) do draw_analysis_stat(
			"FIREBALL: Lasts for %.0f seconds,\n %.0f pixels long, dealing %.0f damage every second.", 
			3, get_fireball_stats(hexagon_type_amounts))
		
		if has_spell(player.clump, .BLACK_HOLE) do draw_analysis_stat(
			"BLACK HOLE: Lasts for %.0f seconds,\n with %.0f suction power, and %.0f pixels long.", 
			4, get_black_hole_stats(hexagon_type_amounts))
		
		for &button in buttons do draw_button(button)
	},
)}

start_death_sequence :: proc() {
	stop_stopwatch(&time_survived)
	game_state = .DEAD
	death_sequence_time_left = 10
	rl.PlayMusicStream(death_music)
}

@(private = "file")
get_grade_score :: proc() -> int {
	grade := int(get_elapsed_stopwatch_time(time_survived) / 50 + f32(killed_hexagons) * 3)
	if len(player.hexagon_types) == MAX_HEXAGONS do grade += 150
	return grade
}

@(private = "file")
get_grade_letter :: proc(num: int) -> cstring {	
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

reset_game :: proc() {
	player = new_player()
	clear(&enemies)
	clear(&pellets)
	clear(&hearts)
	clear(&world_powerups)
	killed_hexagons = 0
	
	start_stopwatch(&time_survived)
	session_playthroughs += 1

	powerup_message_time = 10
	upgrade_message_time = 10
	hexagon_found_time = 0
}

// Helper functions so that I dont have to rewrite the code again and again:

@(private = "file")
draw_menu_title :: proc(text: cstring) {
	draw_text_center(text, {SCREEN_SIZE.x / 2, 70}, 96, .QUICKSAND_HEAVY, border_info = {true, 3, rl.BLACK})
}

@(private = "file")
new_button_def :: proc(text: cstring, center: rl.Vector2, function: proc(), small := false) -> Button {
	return new_button(text, center, function, 64 if !small else 48, .QUICKSAND_MEDIUM, {rl.WHITE, rl.YELLOW}, 5)
}

@(private = "file")
draw_dead_stat :: proc(text: cstring, index: int, args: ..any) {
	str := rl.TextFormat(text, ..args)
	pos := rl.Vector2{SCREEN_SIZE.x / 2 - 275, SCREEN_SIZE.y / 2 - 150 + f32(index) * 40}
	draw_text(str, pos, 32, spacing = 3)
}

@(private = "file")
draw_analysis_stat :: proc(text: cstring, index: int, args: ..any) {
	str := rl.TextFormat(text, ..args)
	pos := rl.Vector2{SCREEN_SIZE.x / 2 - 300, SCREEN_SIZE.y / 2 - 150 + f32(index) * 50}
	count: i32
	strs := rl.TextSplit(str, '\n', &count)
	draw_text(strs[0], pos, 24, spacing = 3)
	draw_text(strs[1], pos + {0, 25}, 24, spacing = 3)
}