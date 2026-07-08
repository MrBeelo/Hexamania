package main

enemies: [dynamic]Enemy

Enemy :: struct {
	using clump: HexagonClump,
}

UpdateEnemies :: proc() { for &enemy, index in enemies do UpdateEnemy(&enemy, index) }

UpdateEnemy :: proc(enemy: ^Enemy, index: int) {
	if enemy.health <= 0 {
		ThrowRandomHeart(enemy.pos)
		unordered_remove(&enemies, index)
	}
	
	UpdateHexagonClump(&enemy.clump)
}

DrawEnemies :: proc() { for enemy in enemies do DrawEnemy(enemy) }

DrawEnemy :: proc(enemy: Enemy) {
	DrawHexagonClump(enemy.clump)
}