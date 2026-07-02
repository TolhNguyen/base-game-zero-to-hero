class_name CwArmy
extends RefCounted
## A field army led by one general. Food is carried thach (spec 13.4).

var id := 0
var general_id: StringName = &""
var general_combat_factor := 1.0
var general_loss_reduction := 0.0
var troops := 0
var morale := 80.0
var food := 0
var pos := Vector2i.ZERO
var state: StringName = &"marching"  # marching | holding | returning
var path: Array[Vector2i] = []
var hold_left := 0
var home_city: StringName = &""
var assault_city: StringName = &""
var victory_cooldown := 0
var starving := false


## Locked formula: 1 thach feeds 100 troops 1 day; 1 turn = 3 days.
func food_per_turn() -> int:
	return ceili(troops / 100.0 * 3.0)
