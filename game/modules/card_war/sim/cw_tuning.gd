class_name CwTuning
extends RefCounted
## Plain tuning values so the sim never touches Registry or Resources.
## Defaults mirror CwScenarioDef; from_def copies a scenario over them.

var turn_limit := 30
var energy_start := 3
var energy_per_turn := 1
var energy_max := 10
var opening_hand := 5
var draw_per_turn := 2
var hand_max := 10
var move_points_per_turn := 6
var march_hold_turns := 2
var troops_per_camp_tile := 2000
var morale_start := 80.0
var starve_morale_loss := 10.0
var victory_morale_gain := 20.0
var defeat_morale_loss := 20.0
var feast_morale_gain := 30.0


static func from_def(def: CwScenarioDef) -> CwTuning:
	var t: CwTuning = CwTuning.new()
	t.turn_limit = def.turn_limit
	t.energy_start = def.energy_start
	t.energy_per_turn = def.energy_per_turn
	t.energy_max = def.energy_max
	t.opening_hand = def.opening_hand
	t.draw_per_turn = def.draw_per_turn
	t.hand_max = def.hand_max
	t.move_points_per_turn = def.move_points_per_turn
	t.march_hold_turns = def.march_hold_turns
	t.troops_per_camp_tile = def.troops_per_camp_tile
	t.morale_start = def.morale_start
	t.starve_morale_loss = def.starve_morale_loss
	t.victory_morale_gain = def.victory_morale_gain
	t.defeat_morale_loss = def.defeat_morale_loss
	t.feast_morale_gain = def.feast_morale_gain
	return t
