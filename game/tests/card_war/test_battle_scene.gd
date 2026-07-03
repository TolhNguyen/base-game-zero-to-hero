extends GdUnitTestSuite

const BattleScript := preload("res://modules/card_war/ui/battle.gd")
const OrderScript := preload("res://modules/card_war/sim/cw_order.gd")


class FakeRegistry:
	extends Node

	var defs := {}

	func get_def(id: StringName) -> Definition:
		return defs.get(id, null)

	func has_def(id: StringName) -> bool:
		return defs.has(id)

	func ids_with_prefix(prefix: String) -> Array[StringName]:
		var out: Array[StringName] = []
		for id: StringName in defs.keys():
			if String(id).begins_with(prefix):
				out.append(id)
		out.sort()
		return out


func _tutorial_registry() -> FakeRegistry:
	var reg := FakeRegistry.new()
	reg.defs[&"scenario.tutorial_01"] = load("res://content/scenarios/scenario.tutorial_01.tres")
	reg.defs[&"map.tutorial_01"] = load("res://content/maps/map.tutorial_01.tres")
	for f: String in ["plains", "forest", "river", "mountain", "city_home", "city_enemy"]:
		var terrain: CwTerrainDef = load("res://content/terrains/terrain.%s.tres" % f)
		reg.defs[terrain.id] = terrain
	for f: String in ["march", "gather_food", "build_camp", "transport", "assault", "feast"]:
		var card: CwCardDef = load("res://content/cards/card.%s.tres" % f)
		reg.defs[card.id] = card
	var general: CwGeneralDef = load("res://content/generals/general.asun.tres")
	reg.defs[general.id] = general
	return reg


func test_battle_scene_builds_state_from_content() -> void:
	var scene: PackedScene = load("res://modules/card_war/ui/battle.tscn")
	var battle: Node2D = auto_free(scene.instantiate())
	add_child(battle)
	var s: CwState = battle.state
	assert_object(s).is_not_null()
	assert_int(s.cities.size()).is_equal(2)
	assert_int(s.hand.size()).is_equal(5)
	assert_that(s.map.size).is_equal(Vector2i(16, 16))
	remove_child(battle)


func test_end_turn_resolves_and_reports() -> void:
	var scene: PackedScene = load("res://modules/card_war/ui/battle.tscn")
	var battle: Node2D = auto_free(scene.instantiate())
	add_child(battle)
	var s: CwState = battle.state
	battle._end_turn()
	assert_int(s.turn).is_equal(2)
	assert_bool(battle._report_panel.visible).is_true()
	assert_bool(battle._report_text.text.length() > 0).is_true()
	remove_child(battle)


func test_order_controls_have_task_211_safe_defaults() -> void:
	var scene: PackedScene = load("res://modules/card_war/ui/battle.tscn")
	var battle: Node2D = auto_free(scene.instantiate())
	add_child(battle)
	assert_int(int(battle._troops_spin.min_value)).is_equal(100)
	assert_int(int(battle._troops_spin.max_value)).is_equal(10000)
	assert_int(int(battle._troops_spin.step)).is_equal(100)
	assert_int(int(battle._troops_spin.value)).is_equal(2000)
	assert_int(int(battle._food_spin.min_value)).is_equal(30)
	assert_int(int(battle._food_spin.max_value)).is_equal(5000)
	assert_int(int(battle._food_spin.step)).is_equal(30)
	assert_int(int(battle._food_spin.value)).is_equal(300)
	remove_child(battle)


func test_end_turn_publishes_victory_and_disables_button() -> void:
	var bus: Node = get_node("/root/EventBus")
	var published: Array[Dictionary] = []
	var cb := func(payload: Dictionary) -> void:
		published.append(payload.duplicate())
	bus.subscribe(&"card_war.victory", cb)

	var scene: PackedScene = load("res://modules/card_war/ui/battle.tscn")
	var battle: Node2D = auto_free(scene.instantiate())
	add_child(battle)
	var s: CwState = battle.state
	var enemy: CwCity = s.cities[&"city.enemy"]
	enemy.troops = 1

	var army := CwArmy.new()
	army.id = 9001
	army.pos = Vector2i(8, 3)
	army.state = &"holding"
	army.troops = 4000
	army.food = 1000
	army.morale = 100.0
	army.home_city = &"city.home"
	s.armies[army.id] = army

	var order: CwOrder = OrderScript.new()
	order.card_id = &"card.assault"
	order.type = &"assault"
	order.params = {"army_id": army.id, "city": &"city.enemy"}
	s.pending.append(order)

	battle._end_turn()
	assert_str(String(s.result)).is_equal("victory")
	assert_bool(battle._end_turn_btn.disabled).is_true()
	assert_int(published.size()).is_equal(1)
	assert_int(int(published[0]["turn"])).is_equal(s.turn)

	bus.unsubscribe(&"card_war.victory", cb)
	remove_child(battle)


func test_build_state_rejects_missing_scenario_deck_card() -> void:
	var battle: Node2D = auto_free(BattleScript.new())
	var reg: FakeRegistry = auto_free(_tutorial_registry())
	reg.defs.erase(&"card.assault")
	var result: CwState = null
	await assert_error(func() -> void:
		result = battle._build_state(reg)
	).is_push_error("Card War battle scenario deck references missing card 'card.assault'.")
	assert_object(result).is_null()


func test_march_order_flow_queues_order() -> void:
	var scene: PackedScene = load("res://modules/card_war/ui/battle.tscn")
	var battle: Node2D = auto_free(scene.instantiate())
	add_child(battle)
	var s: CwState = battle.state
	s.hand.clear()
	s.hand.append(&"card.march")
	battle._refresh()
	battle._begin_card(&"card.march")
	battle._troops_spin.value = 2000
	battle._on_tile_clicked(Vector2i(8, 3))
	battle._confirm_order()
	assert_int(s.pending.size()).is_equal(1)
	assert_int(s.energy).is_equal(1)  # 3 - march cost 2
	var o: CwOrder = s.pending[0]
	assert_that(o.params["to"]).is_equal(Vector2i(8, 3))
	assert_int(int(o.params["troops"])).is_equal(2000)
	remove_child(battle)


func test_rejected_order_reports_reason_and_keeps_state() -> void:
	var scene: PackedScene = load("res://modules/card_war/ui/battle.tscn")
	var battle: Node2D = auto_free(scene.instantiate())
	add_child(battle)
	var s: CwState = battle.state
	s.hand.clear()
	s.hand.append(&"card.march")
	battle._begin_card(&"card.march")
	battle._troops_spin.value = 9000  # more than the city holds
	battle._on_tile_clicked(Vector2i(8, 3))
	battle._confirm_order()
	assert_int(s.pending.size()).is_equal(0)
	assert_int(s.energy).is_equal(3)
	assert_bool(battle._status_label.text.contains("rejected")).is_true()
	remove_child(battle)