extends GdUnitTestSuite

const StateScript := preload("res://modules/card_war/sim/cw_state.gd")
const GridScript := preload("res://modules/card_war/sim/cw_map_grid.gd")
const TuningScript := preload("res://modules/card_war/sim/cw_tuning.gd")
const OrderScript := preload("res://modules/card_war/sim/cw_order.gd")
const ResolverScript := preload("res://modules/card_war/sim/cw_resolver.gd")
const ArmyScript := preload("res://modules/card_war/sim/cw_army.gd")
const CityScript := preload("res://modules/card_war/sim/cw_city.gd")
const CombatScript := preload("res://modules/card_war/sim/cw_combat.gd")

const COSTS := {"P": 2, "F": 3, "R": 0, "M": 0, "H": 2, "E": 2}


func _army(troops: int, morale: float, loss_reduction: float) -> CwArmy:
	var a: CwArmy = ArmyScript.new()
	a.troops = troops
	a.morale = morale
	a.general_combat_factor = 1.0
	a.general_loss_reduction = loss_reduction
	return a


func _city(troops: int, morale: float, wall: float) -> CwCity:
	var c: CwCity = CityScript.new()
	c.troops = troops
	c.morale = morale
	c.wall_factor = wall
	c.owner_side = &"enemy"
	return c


func test_assault_formula_strong_attacker() -> void:
	var r: Dictionary = CombatScript.assault(_army(4000, 80.0, 0.25), _city(1000, 80.0, 1.5))
	assert_bool(r["won"]).is_true()
	assert_int(r["def_losses"]).is_equal(800)
	assert_int(r["att_losses"]).is_equal(225)
	assert_bool(r["captured"]).is_false()


func test_assault_formula_weak_attacker() -> void:
	var r: Dictionary = CombatScript.assault(_army(500, 80.0, 0.0), _city(1000, 80.0, 1.5))
	assert_bool(r["won"]).is_false()
	assert_int(r["att_losses"]).is_equal(250)
	assert_int(r["def_losses"]).is_equal(33)


func test_asun_loss_reduction_applies() -> void:
	var with_asun: Dictionary = CombatScript.assault(_army(4000, 80.0, 0.25), _city(1000, 80.0, 1.5))
	var without: Dictionary = CombatScript.assault(_army(4000, 80.0, 0.0), _city(1000, 80.0, 1.5))
	assert_int(int(with_asun["att_losses"])).is_less(int(without["att_losses"]))


func _battle_state() -> CwState:
	var s: CwState = StateScript.new()
	var g: CwMapGrid = GridScript.from_rows(PackedStringArray(["HPPPPE"]), COSTS)
	s.setup(g, TuningScript.new(), 42)
	s.register_card(&"card.assault", &"assault", 3)
	s.register_card(&"card.gather_food", &"gather_food", 1)
	s.register_card(&"card.feast", &"feast", 1)
	s.register_general(&"general.asun", 1.0, 0.25)
	var home_tiles: Array[Vector2i] = [Vector2i(0, 0)]
	s.add_city(&"city.home", &"player", home_tiles, 1000, 2000, 40, 1.0)
	var enemy_tiles: Array[Vector2i] = [Vector2i(5, 0)]
	s.add_city(&"city.enemy", &"enemy", enemy_tiles, 1000, 500, 40, 1.5)
	var a: CwArmy = ArmyScript.new()
	a.id = s.next_id()
	a.general_id = &"general.asun"
	a.general_combat_factor = 1.0
	a.general_loss_reduction = 0.25
	a.troops = 4000
	a.morale = 80.0
	a.food = 2000
	a.pos = Vector2i(4, 0)
	a.state = &"holding"
	a.hold_left = 2
	a.home_city = &"city.home"
	s.armies[a.id] = a
	s.set_general_busy(&"general.asun", true)
	var cards: Array[StringName] = [&"card.assault", &"card.assault", &"card.gather_food",
			&"card.feast", &"card.feast", &"card.assault"]
	s.set_deck(cards)
	var forced_hand: Array[StringName] = [&"card.assault", &"card.assault",
			&"card.gather_food", &"card.feast", &"card.feast"]
	s.hand = forced_hand
	s.energy = 10
	return s


func _play(s: CwState, card: StringName, type: StringName, params: Dictionary) -> Error:
	var o: CwOrder = OrderScript.new()
	o.card_id = card
	o.type = type
	o.params = params
	return s.play_card(o)


func _assert_invalid_atomic(s: CwState, card: StringName,
		type: StringName, params: Dictionary) -> void:
	var hand_before: Array[StringName] = s.hand.duplicate()
	var discard_before: Array[StringName] = s.discard.duplicate()
	var energy_before: int = s.energy
	var pending_before: int = s.pending.size()
	assert_int(_play(s, card, type, params)).is_equal(ERR_INVALID_PARAMETER)
	assert_that(s.hand).is_equal(hand_before)
	assert_that(s.discard).is_equal(discard_before)
	assert_int(s.energy).is_equal(energy_before)
	assert_int(s.pending.size()).is_equal(pending_before)


func test_two_assaults_capture_city_then_victory() -> void:
	var s: CwState = _battle_state()
	var a: CwArmy = s.armies.values()[0]
	var enemy: CwCity = s.cities[&"city.enemy"]
	assert_int(_play(s, &"card.assault", &"assault",
			{"army_id": a.id, "city": &"city.enemy"})).is_equal(OK)
	ResolverScript.resolve(s)
	assert_int(enemy.troops).is_equal(200)
	assert_str(String(enemy.owner_side)).is_equal("enemy")
	assert_float(a.morale).is_equal_approx(100.0, 0.01)
	assert_int(a.hold_left).is_equal(2)
	assert_int(_play(s, &"card.assault", &"assault",
			{"army_id": a.id, "city": &"city.enemy"})).is_equal(OK)
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_str(String(enemy.owner_side)).is_equal("player")
	assert_int(a.victory_cooldown).is_equal(2)
	assert_str(String(s.result)).is_equal("victory")
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"assault", &"victory"])


func test_gather_food_adds_three_days_production() -> void:
	var s: CwState = _battle_state()
	var home: CwCity = s.cities[&"city.home"]
	assert_int(_play(s, &"card.gather_food", &"gather_food",
			{"city": &"city.home"})).is_equal(OK)
	ResolverScript.resolve(s)
	assert_int(home.food).is_equal(2210)


func test_feast_needs_recent_victory_and_costs_food() -> void:
	var s: CwState = _battle_state()
	var a: CwArmy = s.armies.values()[0]
	assert_int(_play(s, &"card.feast", &"feast",
			{"target_kind": &"army", "target_id": a.id})).is_equal(ERR_INVALID_PARAMETER)
	a.victory_cooldown = 2
	a.morale = 60.0
	var food_before: int = a.food
	assert_int(_play(s, &"card.feast", &"feast",
			{"target_kind": &"army", "target_id": a.id})).is_equal(OK)
	ResolverScript.resolve(s)
	assert_float(a.morale).is_equal_approx(90.0, 0.01)
	assert_int(a.food).is_equal(food_before - 40 - 120)
	assert_int(a.victory_cooldown).is_equal(0)


func test_feast_city_target_costs_food_and_clears_recent_victory() -> void:
	var s: CwState = _battle_state()
	var home: CwCity = s.cities[&"city.home"]
	home.victory_cooldown = 2
	home.morale = 60.0
	assert_int(_play(s, &"card.feast", &"feast",
			{"target_kind": &"city", "target_id": &"city.home"})).is_equal(OK)
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_float(home.morale).is_equal_approx(90.0, 0.01)
	assert_int(home.food).is_equal(2000 - 10 + 120 - 30)
	assert_int(home.victory_cooldown).is_equal(0)
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"feast_held"])


func test_assault_order_is_removed_after_resolve() -> void:
	var s: CwState = _battle_state()
	var a: CwArmy = s.armies.values()[0]
	assert_int(_play(s, &"card.assault", &"assault",
			{"army_id": a.id, "city": &"city.enemy"})).is_equal(OK)
	ResolverScript.resolve(s)
	assert_int(s.pending.size()).is_equal(0)
	assert_str(String(a.assault_city)).is_equal("")


func test_duplicate_assault_for_same_army_is_rejected_atomically() -> void:
	var s: CwState = _battle_state()
	var a: CwArmy = s.armies.values()[0]
	var params: Dictionary = {"army_id": a.id, "city": &"city.enemy"}
	assert_int(_play(s, &"card.assault", &"assault", params)).is_equal(OK)
	_assert_invalid_atomic(s, &"card.assault", &"assault", params)


func test_duplicate_feast_for_same_army_is_rejected_atomically() -> void:
	var s: CwState = _battle_state()
	var a: CwArmy = s.armies.values()[0]
	a.victory_cooldown = 2
	var params: Dictionary = {"target_kind": &"army", "target_id": a.id}
	assert_int(_play(s, &"card.feast", &"feast", params)).is_equal(OK)
	_assert_invalid_atomic(s, &"card.feast", &"feast", params)


func test_duplicate_feast_for_same_city_is_rejected_atomically() -> void:
	var s: CwState = _battle_state()
	var home: CwCity = s.cities[&"city.home"]
	home.victory_cooldown = 2
	var params: Dictionary = {"target_kind": &"city", "target_id": &"city.home"}
	assert_int(_play(s, &"card.feast", &"feast", params)).is_equal(OK)
	_assert_invalid_atomic(s, &"card.feast", &"feast", params)


func test_stale_pending_feast_is_skipped_defensively() -> void:
	var s: CwState = _battle_state()
	var a: CwArmy = s.armies.values()[0]
	a.victory_cooldown = 2
	a.morale = 60.0
	var food_before: int = a.food
	assert_int(_play(s, &"card.feast", &"feast",
			{"target_kind": &"army", "target_id": a.id})).is_equal(OK)
	a.victory_cooldown = 0
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_float(a.morale).is_equal_approx(60.0, 0.01)
	assert_int(a.food).is_equal(food_before - 120)
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).not_contains([&"feast_held"])


func test_loss_reduction_above_one_cannot_create_negative_losses() -> void:
	var r: Dictionary = CombatScript.assault(_army(4000, 80.0, 1.5), _city(1000, 80.0, 1.5))
	assert_int(r["att_losses"]).is_greater_equal(0)


func test_bad_loss_reduction_does_not_increase_army_troops() -> void:
	var s: CwState = _battle_state()
	var a: CwArmy = s.armies.values()[0]
	a.general_loss_reduction = 1.5
	var troops_before: int = a.troops
	assert_int(_play(s, &"card.assault", &"assault",
			{"army_id": a.id, "city": &"city.enemy"})).is_equal(OK)
	ResolverScript.resolve(s)
	assert_int(a.troops).is_less_equal(troops_before)
