package main

import rl "vendor:raylib"

toolbar_messages: [2]string
has_moved: bool
has_sprinted: bool
has_shot: bool
has_found_upgrade: bool
upgrade_message_time := f32(10)
has_found_spell: bool
has_opened_spell_menu: bool
has_used_spell: bool
level_up_time: f32

UpdateToolbar :: proc() {
	toolbar_messages = {}
	if session_playthroughs == 1 {
		if has_opened_spell_menu && !has_used_spell do toolbar_messages = {"Scroll to the spell you like,", "then press Left Click to activate it!"}
		if has_found_spell && !has_opened_spell_menu do toolbar_messages = {"You found a spell!", "Press Right Click to open the spell menu"}
		if has_found_upgrade && upgrade_message_time > 0 {
			upgrade_message_time -= rl.GetFrameTime()
			if upgrade_message_time > 5 {
				toolbar_messages = {"You found an upgrade!", "Upgrades make your stats better!"}
			} else {
				toolbar_messages = {"You can find analytics about your upgrades", "by pressing Left Control."}
			}
		}
		if !has_shot do toolbar_messages = {"Left Click to Shoot", ""}
		if !has_sprinted do toolbar_messages = {"Left Shift to Sprint", ""}
		if !has_moved do toolbar_messages = {"WASD / Arrow Keys to Move", ""}
	}
	
	if player.health < 20 do toolbar_messages = {"WARNING", "LOW HEALTH"}
	if level_up_time > 0 {
		level_up_time -= rl.GetFrameTime()
		toolbar_messages = {"LEVEL UP", ""}
	}
}

DrawToolbar :: proc() {
	DrawTextCenter(toolbar_messages[0], {screen_size.x / 2, 50}, 32)
	DrawTextCenter(toolbar_messages[1], {screen_size.x / 2, 80}, 32)
}