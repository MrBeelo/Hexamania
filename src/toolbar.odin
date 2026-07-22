package main

import rl "vendor:raylib"

toolbar_messages: [2]cstring
has_moved: bool
has_sprinted: bool
has_shot: bool
has_found_powerup: bool
powerup_message_time := f32(10)
has_found_upgrade: bool
upgrade_message_time := f32(10)
has_found_spell: bool
has_opened_spell_menu: bool
has_used_spell: bool
level_up_time: f32
last_hexagon_found: HexagonType
hexagon_found_time := f32(0)
has_killed_enemy: bool

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
		if has_found_powerup && powerup_message_time > 0 {
			powerup_message_time -= rl.GetFrameTime()
			if powerup_message_time > 5 {
				toolbar_messages = {"You found a powerup!", "Powerups give temporary buffs!"}
			} else {
				toolbar_messages = {"You can see your active powerups", "above the map."}
			}
		}
		if has_killed_enemy && !has_found_spell && !has_found_upgrade do toolbar_messages = {"Pick up its heart to", "MERGE with it!"}
		if !has_killed_enemy do toolbar_messages = {"Go find an enemy and kill them!", "(look for red dots in your map for help)"}
		if !has_shot do toolbar_messages = {"Left Click to Shoot", ""}
		if !has_sprinted do toolbar_messages = {"Left Shift to Sprint", ""}
		if !has_moved do toolbar_messages = {"WASD / Arrow Keys to Move", ""}
	}
	
	if player.health < 20 do toolbar_messages = {"WARNING", "LOW HEALTH"}
	if level_up_time > 0 {
		level_up_time -= rl.GetFrameTime()
		toolbar_messages = {"LEVEL UP", ""}
	}
	
	can_show_upgrade_text := (has_found_upgrade && upgrade_message_time <= 0 && session_playthroughs == 1) || session_playthroughs != 1
	can_show_spell_text := (has_found_spell && has_opened_spell_menu && has_used_spell && session_playthroughs == 1) || session_playthroughs != 1
	
	if IsUpgrade(last_hexagon_found) && can_show_upgrade_text && hexagon_found_time > 0 {
		hexagon_found_time -= rl.GetFrameTime()
		msg1 := rl.TextFormat("Found new upgrade for %s", GetHexagonName(GetCorrespondingSpellAsHexagon(last_hexagon_found)))
		msg2 := rl.TextFormat("%s", GetHexagonName(last_hexagon_found))
		toolbar_messages = {msg1, msg2}
	}
	
	if IsSpell(last_hexagon_found) && can_show_spell_text && hexagon_found_time > 0 {
		hexagon_found_time -= rl.GetFrameTime()
		msg1 := rl.TextFormat("Found new spell: %s", GetHexagonName(last_hexagon_found))
		msg2: cstring
		#partial switch last_hexagon_found {
		case .HEALTH_PAD: msg2 = "Throw a health pad down to heal yourself!"
		case .ICE_BALL: msg2 = "Throw an ice ball to freeze enemies!"
		case .FIREBALL: msg2 = "Throw a fireball to burn enemies!"
		case .BLACK_HOLE: msg2 = "Throw a black hole to suck enemies to it!"
		}
		toolbar_messages = {msg1, msg2}
	}
}

DrawToolbar :: proc() {
	DrawTextCenter(toolbar_messages[0], {SCREEN_SIZE.x / 2, 50}, 32, spacing = 2)
	DrawTextCenter(toolbar_messages[1], {SCREEN_SIZE.x / 2, 80}, 32, spacing = 2)
}