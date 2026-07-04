class_name CwCamp
extends RefCounted
## A camp: an army dug in. No production; footprint ~2000 troops/tile.

var id := 0
var pos := Vector2i.ZERO
var troops := 0
var food := 0
var morale := 80.0
var general_id: StringName = &""
var home_city: StringName = &""
var footprint_tiles := 1
var starving := false


func food_per_turn() -> int:
	return ceili(troops / 100.0 * 3.0)
