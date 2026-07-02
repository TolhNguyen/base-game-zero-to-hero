extends GdUnitTestSuite

const CardDefScript := preload("res://modules/card_war/sim/cw_card_def.gd")
const ScenarioDefScript := preload("res://modules/card_war/sim/cw_scenario_def.gd")


func test_card_def_defaults() -> void:
	var def: CwCardDef = CardDefScript.new()
	assert_str(def.display_name).is_equal("")
	assert_int(def.energy_cost).is_equal(1)
	assert_str(String(def.order_type)).is_equal("")
	assert_bool(def is Definition).is_true()

	def.id = &"card.test"
	def.energy_cost = 2
	def.order_type = &"march"
	assert_str(String(def.order_type)).is_equal("march")


func test_scenario_def_carries_tuning() -> void:
	var s: CwScenarioDef = ScenarioDefScript.new()
	assert_int(s.energy_start).is_equal(3)
	assert_int(s.move_points_per_turn).is_equal(6)
	assert_int(s.turn_limit).is_equal(30)
	assert_that(s.deck).is_equal({})
