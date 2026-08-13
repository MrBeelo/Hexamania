package main

import rl "raylib"
import "core:fmt"

DrawDebug :: proc() {
	GROUP_BOX_POS :: rl.Vector2{10, 10}
	GROUP_BOX_X_BUFFER :: f32(3)
	LABEL_PADDING :: rl.Vector2{5, 5}
	LABEL_CHILD_GAP :: f32(5)
	
	font := rl.GuiGetFont()
	font_size := f32(rl.GuiGetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE)))
	font_spacing := f32(rl.GuiGetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SPACING)))
	
	strs := [?]cstring {
		fmt.ctprintf("pos: %d, %d", int(player.pos.x), int(player.pos.y)),
		fmt.ctprintf("vel: %d, %d", int(player.vel.x), int(player.vel.y)),
		fmt.ctprintf("speed: %d", int(GetPlayerSpeed(player))),
		fmt.ctprintf("acc: %d", PLAYER_ACCELERATION),
		fmt.ctprintf("time survived: %ds", int(GetElapsedStopwatchTime(time_survived))),
		fmt.ctprintf("score: %d", killed_hexagons),
		fmt.ctprintf("fps: %d", rl.GetFPS()),
		fmt.ctprintf("enemies: %d", len(enemies)),
		fmt.ctprintf("powerups: %d", len(world_powerups)),
	}

	longest_text_size_x: f32

	for str in strs {
		size_x := rl.MeasureTextEx(font, str, font_size, font_spacing).x
		if size_x > longest_text_size_x do longest_text_size_x = size_x
	}

	// Drawing Pass

	// Group Box (rectangle with the word "Values" in it)
	group_box_bounds := rl.Rectangle{
		GROUP_BOX_POS.x, GROUP_BOX_POS.y, 
		longest_text_size_x + LABEL_PADDING.x * 2 + GROUP_BOX_X_BUFFER, 
		font_size * len(strs) + LABEL_CHILD_GAP * (len(strs) - 1) + LABEL_PADDING.y * 2,
	}

	rl.GuiGroupBox(group_box_bounds, "Values")

	// Value labels
	
	for str, index in strs {
		bounds := rl.Rectangle{
			GROUP_BOX_POS.x + LABEL_PADDING.x, 
			GROUP_BOX_POS.y + LABEL_PADDING.y + f32(index) * (font_size + LABEL_CHILD_GAP), 
			longest_text_size_x + GROUP_BOX_X_BUFFER, // Note: with new raygui (5.0), text bounds width must be a tiny bit bigger, or else '...' will appear.
			font_size,
		}
		
		rl.GuiLabel(bounds, str)
	}

	// Invincibility toggle
	{
		toggle_text := cstring("Invincibility")
		toggle_bounds := rl.Rectangle{
			group_box_bounds.x, group_box_bounds.y + group_box_bounds.height + LABEL_PADDING.y,
			rl.MeasureTextEx(font, toggle_text, font_size, font_spacing).x + LABEL_PADDING.x * 2,
			font_size + LABEL_PADDING.y * 2,
		}

		rl.GuiToggle(toggle_bounds, toggle_text, &player.invincible)
	}

	// Add Hexagon Button
	{
		button_text := cstring("Add Hexagon")
		button_bounds := rl.Rectangle{
			group_box_bounds.x, group_box_bounds.y + group_box_bounds.height + LABEL_PADDING.y * 4 + font_size,
			rl.MeasureTextEx(font, button_text, font_size, font_spacing).x + LABEL_PADDING.x * 2,
			font_size + LABEL_PADDING.y * 2,
		}

		result := rl.GuiButton(button_bounds, button_text)
		if result == 1 do AddHexagonToClump(&player.clump, .RIFLE)
	}
}