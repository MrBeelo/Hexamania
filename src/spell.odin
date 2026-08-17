package main

import rl "raylib"
import "core:encoding/uuid"
import "core:math"
import "core:math/rand"

Spell_Type :: enum { HEALTH_PAD, ICE_BALL, FIREBALL, BLACK_HOLE }
spell_textures: [Spell_Type]rl.Texture2D

spells: [dynamic]Spell
Spell :: union {
	Health_Pad,
	Ice_Ball,
	Fireball,
	Black_Hole,
}

load_spells :: proc() {
	spell_textures = {
		.HEALTH_PAD = rl.LoadTexture("texture/spell/health_pad_texture.png"),
		.ICE_BALL = rl.LoadTexture("texture/spell/ice_ball_texture.png"),
		.FIREBALL = rl.LoadTexture("texture/spell/fireball_texture_sheet.png"),
		.BLACK_HOLE = rl.LoadTexture("texture/spell/black_hole_texture.png"),
	}

	for texture in spell_textures do rl.SetTextureFilter(texture, .BILINEAR)
}

unload_spells :: proc() {
	for spell in spell_textures do rl.UnloadTexture(spell)
}

update_spells :: proc() {
	for &spell, index in spells do switch &s in spell {
	case Health_Pad: update_health_pad(&s, index)
	case Ice_Ball: update_ice_ball(&s, index)
	case Fireball: update_fireball(&s, index)
	case Black_Hole: update_black_hole(&s, index)
	}
}

draw_spells_bottom_layer :: proc() {
	for spell in spells do #partial switch s in spell {
	case Health_Pad: draw_health_pad(s)
	}
}

draw_spells_top_layer :: proc() {
	for spell in spells do #partial switch s in spell {
	case Ice_Ball: draw_ice_ball(s)
	case Fireball: draw_fireball(s)
	case Black_Hole: draw_black_hole(s)
	}
}

has_spell :: proc(clump: Hexagon_Clump, spell: Spell_Type) -> bool {
	hexagon_type_amounts := get_hexagon_type_amounts(clump)
	switch spell {
	case .HEALTH_PAD: return hexagon_type_amounts[.HEALTH_PAD] > 0
	case .ICE_BALL: return hexagon_type_amounts[.ICE_BALL] > 0
	case .FIREBALL: return hexagon_type_amounts[.FIREBALL] > 0
	case .BLACK_HOLE: return hexagon_type_amounts[.BLACK_HOLE] > 0
	}

	return false
}

hexagon_to_spell :: proc(type: Hexagon_Type) -> Maybe(Spell_Type) {
	switch type {
	case .RIFLE, .RIFLE_UPGRADE_FIRE_RATE, .RIFLE_UPGRADE_PELLET_SPEED, .RIFLE_UPGRADE_DAMAGE: return nil
	case .HEALTH_PAD, .HEALTH_PAD_UPGRADE_HEAL_AMOUNT, .HEALTH_PAD_UPGRADE_SIZE, .HEALTH_PAD_UPGRADE_TIME: return .HEALTH_PAD
	case .ICE_BALL, .ICE_BALL_UPGRADE_RANGE, .ICE_BALL_UPGRADE_SIZE, .ICE_BALL_UPGRADE_FREEZE_TIME: return .ICE_BALL
	case .FIREBALL, .FIREBALL_UPGRADE_SIZE, .FIREBALL_UPGRADE_BURN_TIME, .FIREBALL_UPGRADE_DAMAGE: return .FIREBALL
	case .BLACK_HOLE, .BLACK_HOLE_UPGRADE_SUCTION_POWER, .BLACK_HOLE_UPGRADE_SIZE, .BLACK_HOLE_UPGRADE_TIME: return .BLACK_HOLE
	}

	return nil
}

spell_to_hexagon :: proc(spell: Maybe(Spell_Type)) -> Hexagon_Type {
	switch spell {
	case nil: return .RIFLE
	case .HEALTH_PAD: return .HEALTH_PAD
	case .ICE_BALL: return .ICE_BALL
	case .FIREBALL: return .FIREBALL
	case .BLACK_HOLE: return .BLACK_HOLE
	}
	return .RIFLE
}

// nil corresponds to RIFLE
spell_to_upgrades :: proc(spell: Maybe(Spell_Type)) -> [3]Hexagon_Type {
	if spell == nil do return {.RIFLE_UPGRADE_FIRE_RATE, .RIFLE_UPGRADE_PELLET_SPEED, .RIFLE_UPGRADE_DAMAGE}
	switch spell.? {
	case .HEALTH_PAD: return {.HEALTH_PAD_UPGRADE_HEAL_AMOUNT, .HEALTH_PAD_UPGRADE_SIZE, .HEALTH_PAD_UPGRADE_TIME}
	case .ICE_BALL: return {.ICE_BALL_UPGRADE_RANGE, .ICE_BALL_UPGRADE_SIZE, .ICE_BALL_UPGRADE_FREEZE_TIME}
	case .FIREBALL: return {.FIREBALL_UPGRADE_SIZE, .FIREBALL_UPGRADE_BURN_TIME, .FIREBALL_UPGRADE_DAMAGE}
	case .BLACK_HOLE: return {.BLACK_HOLE_UPGRADE_SUCTION_POWER, .BLACK_HOLE_UPGRADE_SIZE, .BLACK_HOLE_UPGRADE_TIME}
	}

	return {.RIFLE, .RIFLE, .RIFLE}
}

SPELL_COOLDOWN :: f32(25)

player_do_spell :: proc(type: Spell_Type) {
	switch type {
	case .HEALTH_PAD: summon_health_pad(&player.clump)
	case .ICE_BALL: player_throw_ice_ball()
	case .FIREBALL: player_throw_fireball()
	case .BLACK_HOLE: player_throw_black_hole()
	}

	play_sound(fire_spell)
}

enemy_do_spell :: proc(enemy: ^Enemy, type: Spell_Type, target: rl.Vector2) {
	switch type {
	case .HEALTH_PAD: summon_health_pad(&enemy.clump)
	case .ICE_BALL: enemy_throw_ice_ball(enemy, target)
	case .FIREBALL: enemy_throw_fireball(enemy, target)
	case .BLACK_HOLE: enemy_throw_black_hole(enemy, target)
	}

	play_sound(fire_spell, enemy.clump, player.clump)
}

// HEALTH PAD

Health_Pad :: struct { owner: uuid.Identifier, pos: rl.Vector2, size: f32, max_size: f32, heal_amount: f32, heal_timer: Timer, time_left: f32, rot: f32 }

summon_health_pad :: proc(clump: ^Hexagon_Clump) {
	time_left, size, heal_amount := get_health_pad_stats(get_hexagon_type_amounts(clump^))

	//rect := rl.Rectangle{clump.pos.x - size / 2, clump.pos.y - size / 2, size, size}
	heal_timer := new_timer(1, true, true)
	rot := f32(rand.int_range(0, 4)) * 90
	health_pad := Health_Pad{clump.uuid, clump.pos, size, size, heal_amount, heal_timer, time_left, rot}

	append(&spells, health_pad)
	clump.spell_cooldowns[.HEALTH_PAD] = SPELL_COOLDOWN
}

update_health_pad :: proc(pad: ^Health_Pad, index: int) {
	if pad.time_left <= 0.3 do pad.size = pad.max_size * (pad.time_left / 0.3)
	
	update_timer(&pad.heal_timer)
	if pad.heal_timer.ding do for clump in hexagon_clumps[:clump_cap] {
		if clump.uuid != pad.owner do continue
		rect := rl.Rectangle{pad.pos.x - pad.size / 2, pad.pos.y - pad.size / 2, pad.size, pad.size}
		if clump_intersects_rect(clump^, rect) do heal_clump(clump, pad.heal_amount)
	}

	pad.time_left -= rl.GetFrameTime()
	if pad.time_left < 0 && len(spells) > index do unordered_remove(&spells, index)
}

draw_health_pad :: proc(pad: Health_Pad) {
	src := rl.Rectangle{0, 0, f32(spell_textures[.HEALTH_PAD].width), f32(spell_textures[.HEALTH_PAD].height)}
	color := rl.Color{255, 255, 255, 100} if pad.owner != player.uuid else rl.WHITE
	rect := rl.Rectangle{pad.pos.x, pad.pos.y, pad.size, pad.size}
	rl.DrawTexturePro(spell_textures[.HEALTH_PAD], src, rect, pad.size / 2, pad.rot, color)
}

get_health_pad_stats :: proc(hexagon_type_amounts: [Hexagon_Type]int) -> (time_left: f32, size: f32, heal_amount: f32) {
	time_left = 10 + f32(hexagon_type_amounts[.HEALTH_PAD_UPGRADE_TIME]) * 2
	size = 150 + f32(hexagon_type_amounts[.HEALTH_PAD_UPGRADE_SIZE]) * 33
	heal_amount = 3 + f32(hexagon_type_amounts[.HEALTH_PAD_UPGRADE_HEAL_AMOUNT]) * 2 / 3
	return time_left, size, heal_amount
}

// ICE BALL

ICE_BALL_SPEED :: 400
ICE_BALL_SIZE :: 40

Ice_Ball :: struct { owner: uuid.Identifier, pos: rl.Vector2, vel: rl.Vector2, time_left: f32, 
	size: f32, freeze_time: f32 }

player_throw_ice_ball :: proc() {
	vel := velocity_from_points(world_to_camera(player.pos), rl.GetMousePosition())
	throw_ice_ball(&player.clump, vel)
}

enemy_throw_ice_ball :: proc(enemy: ^Enemy, target: rl.Vector2) {
	rot := rotation_from_points(enemy.pos, target)
	inac := get_enemy_inaccuracy(enemy.ai_state)
	rot += rand.float32_range(-inac, inac)
	vel := velocity_from_rotation(rot)
	throw_ice_ball(&enemy.clump, vel)
}

throw_ice_ball :: proc(clump: ^Hexagon_Clump, vel: rl.Vector2) {
	time_left, floor_size, freeze_time := get_ice_ball_stats(get_hexagon_type_amounts(clump^))
	
	append(&spells, Ice_Ball{clump.uuid, clump.pos, vel, time_left, floor_size, freeze_time})
	clump.spell_cooldowns[.ICE_BALL] = SPELL_COOLDOWN
}

update_ice_ball :: proc(ball: ^Ice_Ball, index: int) {
	for clump in hexagon_clumps[:clump_cap] {
		if clump.uuid == ball.owner do continue
		if clump_intersects_circle(clump^, ball.pos, ball.size) {
			if clump.frozen_time_left <= 0 {
				if clump.uuid == player.uuid do play_sound(freeze); else do play_sound(freeze, clump^, player.clump)
			}
			
			clump.frozen_time_left = ball.freeze_time
		}
	}

	ball.time_left -= rl.GetFrameTime()
	if ball.time_left <= 0 && len(spells) > index do unordered_remove(&spells, index)

	ball.pos += ball.vel * ICE_BALL_SPEED * rl.GetFrameTime()
}

draw_ice_ball :: proc(ball: Ice_Ball) {
	texture := spell_textures[.ICE_BALL]
	src := rl.Rectangle{0, 0, f32(texture.width), f32(texture.height)}
	dest := rl.Rectangle{ball.pos.x, ball.pos.y, ICE_BALL_SIZE, ICE_BALL_SIZE}
	color := rl.WHITE
	rot := math.mod_f32(f32(rl.GetTime() * 100), 360)
	rl.DrawTexturePro(texture, src, dest, ICE_BALL_SIZE / 2, rot, color)
}

get_ice_ball_stats :: proc(hexagon_type_amounts: [Hexagon_Type]int) -> (time_left: f32, size: f32, freeze_time: f32) {
	time_left = 3 + f32(hexagon_type_amounts[.ICE_BALL_UPGRADE_RANGE])
	size = 15 + f32(hexagon_type_amounts[.ICE_BALL_UPGRADE_RANGE]) * 4
	freeze_time = 3 + f32(hexagon_type_amounts[.ICE_BALL_UPGRADE_RANGE])
	return time_left, size, freeze_time
}

// FIREBALL

FIREBALL_SPEED :: 400

Fireball :: struct { owner: uuid.Identifier, pos: rl.Vector2, vel: rl.Vector2, time_left: f32, burn_time: f32, size: f32, damage: f32 }

player_throw_fireball :: proc() {
	vel := velocity_from_points(world_to_camera(player.pos), rl.GetMousePosition())
	throw_fireball(&player.clump, vel)
}

enemy_throw_fireball :: proc(enemy: ^Enemy, target: rl.Vector2) {
	rot := rotation_from_points(enemy.pos, target)
	inac := get_enemy_inaccuracy(enemy.ai_state)
	rot += rand.float32_range(-inac, inac)
	vel := velocity_from_rotation(rot)
	throw_fireball(&enemy.clump, vel)
}

throw_fireball :: proc(clump: ^Hexagon_Clump, vel: rl.Vector2) {
	burn_time, size, damage := get_fireball_stats(get_hexagon_type_amounts(clump^))
	
	append(&spells, Fireball{clump.uuid, clump.pos, vel, 3, burn_time, size, damage})
	clump.spell_cooldowns[.FIREBALL] = SPELL_COOLDOWN
}

update_fireball :: proc(ball: ^Fireball, index: int) {
	exploded := false
	exploded_clump_uuid: uuid.Identifier
	damage_timer := new_timer(1, true, true)
	
	for clump in hexagon_clumps[:clump_cap] {
		if clump.uuid == ball.owner do continue
		if clump_intersects_circle(clump^, ball.pos, ball.size) { 
			if len(spells) > index do unordered_remove(&spells, index)
			damage_clump(clump, 65)
			clump.burning = { damage_timer, ball.burn_time, ball.damage }
			exploded = true
			exploded_clump_uuid = clump.uuid
			play_sound(explosion, 0.6)
		}
	}

	if exploded do for nearby_clump in hexagon_clumps[:clump_cap] {
		if nearby_clump.uuid == exploded_clump_uuid || nearby_clump.uuid == ball.owner do return
		if clump_intersects_circle(nearby_clump^, ball.pos, ball.size * 3) { 
			nearby_clump.burning = { damage_timer, ball.burn_time, ball.damage }
		}
	}

	ball.time_left -= rl.GetFrameTime()
	if ball.time_left <= 0 && len(spells) > index do unordered_remove(&spells, index)

	ball.pos += ball.vel * FIREBALL_SPEED * rl.GetFrameTime()
}

draw_fireball :: proc(ball: Fireball) {
	for i in 0..=2 {
		FIREBALL_TEXTURE_SRC_SIZE :: 256
		src := rl.Rectangle{f32(i) * FIREBALL_TEXTURE_SRC_SIZE, 0, FIREBALL_TEXTURE_SRC_SIZE, FIREBALL_TEXTURE_SRC_SIZE}
		dest := rl.Rectangle{ball.pos.x, ball.pos.y, ball.size, ball.size}
		color := get_burning_overlay_color(f32(i) / 3)
		rot := math.mod_f32(f32(rl.GetTime() * 100), 360)
		rl.DrawTexturePro(spell_textures[.FIREBALL], src, dest, ball.size / 2, rot, color)
	}	
}

get_fireball_stats :: proc(hexagon_type_amounts: [Hexagon_Type]int) -> (burn_time: f32, size: f32, damage: f32) {
	burn_time = 7 + f32(hexagon_type_amounts[.FIREBALL_UPGRADE_BURN_TIME])
	size = 30 + f32(hexagon_type_amounts[.FIREBALL_UPGRADE_SIZE]) * 10
	damage = 3 + f32(hexagon_type_amounts[.FIREBALL_UPGRADE_DAMAGE]) / 2
	return burn_time, size, damage
}

// BLACK HOLE

BLACK_HOLE_SPEED :: 6 * 60
BLACK_HOLE_DECELERATION :: 5 * 60

Black_Hole :: struct { owner: uuid.Identifier, pos: rl.Vector2, vel: rl.Vector2, time_left: f32, suction_power: f32, size: f32, max_size: f32 }

player_throw_black_hole :: proc() {
	vel := velocity_from_points(world_to_camera(player.pos), rl.GetMousePosition())
	throw_black_hole(&player.clump, vel)
}

enemy_throw_black_hole :: proc(enemy: ^Enemy, target: rl.Vector2) {
	rot := rotation_from_points(enemy.pos, target)
	inac := get_enemy_inaccuracy(enemy.ai_state)
	rot += rand.float32_range(-inac, inac)
	vel := velocity_from_rotation(rot)
	throw_black_hole(&enemy.clump, vel)
}

throw_black_hole :: proc(clump: ^Hexagon_Clump, vel: rl.Vector2) {
	time_left, suction_power, size := get_black_hole_stats(get_hexagon_type_amounts(clump^))
	new_vel := vel * BLACK_HOLE_SPEED
	
	append(&spells, Black_Hole{clump.uuid, clump.pos, new_vel, time_left, suction_power, size, size})
	clump.spell_cooldowns[.BLACK_HOLE] = SPELL_COOLDOWN
}

update_black_hole :: proc(hole: ^Black_Hole, index: int) {
	accelerate(&hole.vel.x, 0, BLACK_HOLE_DECELERATION)
	accelerate(&hole.vel.y, 0, BLACK_HOLE_DECELERATION)
	
	for clump in hexagon_clumps[:clump_cap] {
		if clump.uuid == hole.owner do continue
		if rl.Vector2Distance(hole.pos, clump.pos) > hole.size * 25 do continue
		target_vel := velocity_from_points(clump.pos, hole.pos) * 60
		accelerate(&clump.vel.x, target_vel.x, hole.suction_power)
		accelerate(&clump.vel.y, target_vel.y, hole.suction_power)
		if clump_intersects_circle(clump^, hole.pos, hole.size / 3) do clump.vel = 0
		if rl.Vector2Distance(clump.pos, hole.pos) - hole.size - (f32(get_level(clump.hexagon_types)) - 1) * HEXAGON_SIZE < 100 do clump.can_shoot = false
	}

	hole.time_left -= rl.GetFrameTime()
	if hole.time_left <= 0 && len(spells) > index do unordered_remove(&spells, index)

	if hole.time_left <= 1 do hole.size = hole.max_size * hole.time_left
	
	hole.pos += hole.vel * rl.GetFrameTime()
}

draw_black_hole :: proc(hole: Black_Hole) {
	src := rl.Rectangle{0, 0, f32(spell_textures[.BLACK_HOLE].width), f32(spell_textures[.BLACK_HOLE].height)}
	
	DELAY :: 2
	time := f32(rl.GetTime())
	time = math.mod_f32(time, DELAY)
	factor := math.sin(rl.PI * time / DELAY)
	color := rl.ColorLerp(rl.Color{14, 0, 49, 255}, rl.Color{20, 0, 71, 255}, factor)
	if hole.owner == player.uuid do color.a = 200
	
	dest := rl.Rectangle{hole.pos.x, hole.pos.y, hole.size, hole.size}

	rl.DrawTexturePro(spell_textures[.BLACK_HOLE], src, dest, hole.size / 2, 0, color)
}

get_black_hole_stats :: proc(hexagon_type_amounts: [Hexagon_Type]int) -> (time_left: f32, suction_power: f32, size: f32) {
	time_left = 5 + f32(hexagon_type_amounts[.BLACK_HOLE_UPGRADE_TIME])
	suction_power = (6 + f32(hexagon_type_amounts[.BLACK_HOLE_UPGRADE_SUCTION_POWER]) * 3 / 2) * 60
	size = 60 + f32(hexagon_type_amounts[.BLACK_HOLE_UPGRADE_SIZE]) * 10
	return time_left, suction_power, size
}