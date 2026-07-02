class_name CwCity
extends RefCounted
## A city: multi-tile footprint, food store, production, garrison, morale.

var id: StringName = &""
var owner_side: StringName = &"player"  # player | enemy
var tiles: Array[Vector2i] = []
var troops := 0
var food := 0
var production_per_day := 0
var morale := 80.0
var wall_factor := 1.0
var victory_cooldown := 0
var starving := false


func anchor() -> Vector2i:
	return tiles[0] if tiles.size() > 0 else Vector2i.ZERO


func contains(p: Vector2i) -> bool:
	return tiles.has(p)


func food_per_turn() -> int:
	return ceili(troops / 100.0 * 3.0)
