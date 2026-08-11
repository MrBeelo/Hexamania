package main

import rl "raylib"
import "core:fmt"

tutorial_active: bool
TutorialIndex :: enum {
	MOVE,
	SPRINT,
	SHOOT,
	KILL_ENEMY_1, // <before killing enemy> Go kill an enemy ...
	KILL_ENEMY_2, // <after killing enemy> Pick up its heart ...
	FOUND_POWERUP_1, // You found a powerup, ...
	FOUND_POWERUP_2, // You can see active powerups ...
	FOUND_UPGRADE_1, // You found an upgrade, ...
	FOUND_UPGRADE_2, // Left control for analytics ...
	FOUND_SPELL_1, // You found a spell, right click to ...
	FOUND_SPELL_2, // Scroll and left click ...
}

player_action_list: ActionList
ActionList :: struct {
	moved: bool,
	sprinted: bool,
	shot: bool,
	killed_enemy: bool,
	found_powerup: bool,
	found_upgrade: bool,
	found_spell: bool,
	opened_spell_menu: bool,
	used_spell: bool,
	last_hexagon_found: HexagonType,
}

@private powerup_message_time := f32(10)
@private upgrade_message_time := f32(10)
level_up_time: f32
hexagon_found_time: f32

toolbar_messages: [2]cstring

UpdateToolbar :: proc() {	
	toolbar_messages = GetTutorialText()
	pal := player_action_list

	can_show_upgrade_text := (pal.found_upgrade && upgrade_message_time <= 0 && 
		session_playthroughs == 1) || session_playthroughs != 1
	can_show_spell_text := (pal.found_spell && pal.opened_spell_menu && pal.used_spell && 
		session_playthroughs == 1) || session_playthroughs != 1
	
	if IsUpgrade(pal.last_hexagon_found) && can_show_upgrade_text && hexagon_found_time > 0 {
		hexagon_found_time -= rl.GetFrameTime()
		corresponding_spell_hexagon := SpellToHexagon(HexagonToSpell(pal.last_hexagon_found))
		msg1 := fmt.ctprintf("Found new upgrade for %s:", GetHexagonName(corresponding_spell_hexagon))
		msg2 := fmt.ctprintf("%s", GetHexagonName(pal.last_hexagon_found))
		toolbar_messages = {msg1, msg2}
	}
	
	if IsSpell(pal.last_hexagon_found) && can_show_spell_text && hexagon_found_time > 0 {
		hexagon_found_time -= rl.GetFrameTime()
		msg1 := fmt.ctprintf("Found new spell: %s", GetHexagonName(pal.last_hexagon_found))
		msg2: cstring
		#partial switch pal.last_hexagon_found {
		case .HEALTH_PAD: msg2 = "Throw a health pad down to heal yourself!"
		case .ICE_BALL: msg2 = "Throw an ice ball to freeze enemies!"
		case .FIREBALL: msg2 = "Throw a fireball to burn enemies!"
		case .BLACK_HOLE: msg2 = "Throw a black hole to suck enemies to it!"
		}
		toolbar_messages = {msg1, msg2}
	}

	if player.health < 20 do toolbar_messages = {"[cFF0000FF]WARNING[r]", "[cFF0000FF]LOW HEALTH[r]"}
	if level_up_time > 0 {
		level_up_time -= rl.GetFrameTime()
		toolbar_messages = {"LEVEL UP", ""}
	}
}

DrawToolbar :: proc() {
	if toolbar_messages == {} do return
	DrawTextCenter(toolbar_messages[0], {SCREEN_SIZE.x / 2, 50}, 32, spacing = 2)
	DrawTextCenter(toolbar_messages[1], {SCREEN_SIZE.x / 2, 80}, 32, spacing = 2)
}

tutorial_texts := [TutorialIndex][2]cstring {
	.MOVE = {"WASD / Arrow Keys to Move", ""},
	.SPRINT = {"Left Shift to Sprint", ""},
	.SHOOT = {"Left Click to Shoot", ""},
	.KILL_ENEMY_1 = {"Go find an enemy and kill them!", "(look for red dots in your map for help)"},
	.KILL_ENEMY_2 = {"Pick up its heart to", "[cFF0000FF]M[cF57327FF]E[cF5E727FF]R[c46F527FF]G[c27E7F5FF]E[r] with it!"},
	.FOUND_POWERUP_1 = {"You found a powerup!", "Powerups give temporary buffs!"},
	.FOUND_POWERUP_2 = {"You can see your active powerups", "above the map."},
	.FOUND_UPGRADE_1 = {"You found an upgrade!", "Upgrades make your stats better!"},
	.FOUND_UPGRADE_2 = {"You can find analytics about your upgrades", "by pressing Left Control."},
	.FOUND_SPELL_1 = {"You found a spell!", "Press Right Click to open the spell menu"},
	.FOUND_SPELL_2 = {"Scroll to the spell you like,", "then press Left Click to activate it!"},
}

GetTutorialText :: proc() -> [2]cstring {
	index := GetTutorialTextIndex()
	if index == nil do return {}
	return tutorial_texts[index.?]
}

GetTutorialTextIndex :: proc() -> Maybe(TutorialIndex) {
	if session_playthroughs != 1 do return nil

	pal := player_action_list

	if !pal.moved do return .MOVE
	if !pal.sprinted do return .SPRINT
	if !pal.shot do return .SHOOT
	if !pal.killed_enemy do return .KILL_ENEMY_1
	if pal.killed_enemy && !pal.found_upgrade && !pal.found_spell do return .KILL_ENEMY_2

	if pal.found_powerup && powerup_message_time > 0 {
		powerup_message_time -= rl.GetFrameTime()
		return (.FOUND_POWERUP_1 if powerup_message_time > 5 else .FOUND_POWERUP_2)
	}

	if pal.found_upgrade && upgrade_message_time > 0 {
		upgrade_message_time -= rl.GetFrameTime()
		return (.FOUND_UPGRADE_1 if upgrade_message_time > 5 else .FOUND_UPGRADE_2)
	}

	if pal.found_spell && !pal.opened_spell_menu do return .FOUND_SPELL_1
	if pal.opened_spell_menu && !pal.used_spell do return .FOUND_SPELL_2

	return nil
}