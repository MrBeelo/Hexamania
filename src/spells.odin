package main

import rl "vendor:raylib"
import "core:encoding/uuid"

spells: [dynamic]Spell
Spell :: union {
	HealthPad,
}

UpdateSpells :: proc() {
	for &spell, index in spells do switch &x in spell {
	case HealthPad: UpdateHealthPad(&x, index)
	}
}

DrawSpellsBelow :: proc() {
	for spell in spells do switch x in spell {
	case HealthPad: DrawHealthPad(x)
	}
}

HealthPad :: struct { owner: uuid.Identifier, rect: rl.Rectangle, heal_amount: f32, heal_timer: Timer, time_left: f32, }

SummonHealthPad :: proc(clump: HexagonClump) {
	hexagon_type_amounts := GetHexagonTypeAmounts(clump)
	time_left := 10 + f32(hexagon_type_amounts[.HEALTH_PAD_UPGRADE_TIME]) * 5
	size := 150 + f32(hexagon_type_amounts[.HEALTH_PAD_UPGRADE_SIZE]) * 50
	heal_amount := 3 + f32(hexagon_type_amounts[.HEALTH_PAD_UPGRADE_HEAL_AMOUNT])

	rect := rl.Rectangle{clump.pos.x - size / 2, clump.pos.y - size / 2, size, size}
	heal_timer := NewTimer(2, true, true)
	health_pad := HealthPad{clump.uuid, rect, heal_amount, heal_timer, time_left}

	append(&spells, health_pad)
}

UpdateHealthPad :: proc(pad: ^HealthPad, index: int) {
	UpdateTimer(&pad.heal_timer)
	if pad.heal_timer.ding do for clump in GetAllClumps() {
		if clump.uuid != pad.owner do continue
		if ClumpIntersectsRect(clump^, pad.rect) do clump.health += pad.heal_amount
	}

	pad.time_left -= rl.GetFrameTime()
	if pad.time_left < 0 && len(spells) > index do unordered_remove(&spells, index)
}

DrawHealthPad :: proc(pad: HealthPad) {
	rl.DrawRectangleLinesEx(pad.rect, 5, rl.GREEN)
}