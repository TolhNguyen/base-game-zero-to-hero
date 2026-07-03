extends GdUnitTestSuite

const StateScript := preload("res://modules/card_war/sim/cw_state.gd")
const GridScript := preload("res://modules/card_war/sim/cw_map_grid.gd")
const TuningScript := preload("res://modules/card_war/sim/cw_tuning.gd")
const OrderScript := preload("res://modules/card_war/sim/cw_order.gd")
const ResolverScript := preload("res://modules/card_war/sim/cw_resolver.gd")
const ArmyScript := preload("res://modules/card_war/sim/cw_army.gd")

const COSTS := {"P": 2, "F": 3, "R": 0, "M": 0, "H": 2, "E": 2}
const EXPENSIVE_COSTS := {"H": 2, "X": 7}


func _state() -> CwState:
	var s: CwState = StateScript.new()
	var g: CwMapGrid = GridScript.from_rows(PackedStringArray(["HPPPPPPP"]), COSTS)
	s.setup(g, TuningScript.new(), 42)
	s.register_card(&"card.build_camp", &"build_camp", 1)
	s.register_card(&"card.transport", &"transport", 1)
	var home_tiles: Array[Vector2i] = [Vector2i(0, 0)]
	s.add_city(&"city.home", &"player", home_tiles, 3000, 2000, 40, 1.0)
	var enemy_tiles: Array[Vector2i] = [Vector2i(7, 0)]
	s.add_city(&"city.enemy", &"enemy", enemy_tiles, 1000, 500, 40, 1.0)
	var a: CwArmy = ArmyScript.new()
	a.id = s.next_id()
	a.general_id = &"general.asun"
	a.troops = 4000
	a.morale = 75.0
	a.food = 300
	a.pos = Vector2i(6, 0)
	a.state = &"holding"
	a.hold_left = 1
	a.home_city = &"city.home"
	s.armies[a.id] = a
	s.set_general_busy(&"general.asun", true)
	var cards: Array[StringName] = [&"card.build_camp", &"card.transport",
			&"card.transport", &"card.build_camp"]
	s.set_deck(cards)
	s.hand = cards.duplicate()
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


func _only_army(s: CwState) -> CwArmy:
	return s.armies.values()[0] as CwArmy


func test_build_camp_converts_army_and_cancels_return() -> void:
	var s: CwState = _state()
	var a: CwArmy = _only_army(s)
	assert_int(_play(s, &"card.build_camp", &"build_camp",
			{"army_id": a.id})).is_equal(OK)
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_int(s.armies.size()).is_equal(0)
	assert_int(s.camps.size()).is_equal(1)
	if s.camps.size() != 1:
		return
	var camp: CwCamp = s.camps.values()[0]
	assert_that(camp.pos).is_equal(Vector2i(6, 0))
	assert_int(camp.troops).is_equal(4000)
	assert_int(camp.footprint_tiles).is_equal(2)
	assert_int(camp.food).is_equal(180)
	assert_bool(s.is_general_busy(&"general.asun")).is_true()
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"camp_built"])


func test_convoy_delivers_to_camp() -> void:
	var s: CwState = _state()
	var a: CwArmy = _only_army(s)
	_play(s, &"card.build_camp", &"build_camp", {"army_id": a.id})
	ResolverScript.resolve(s)
	assert_int(s.camps.size()).is_equal(1)
	if s.camps.size() != 1:
		return
	var camp: CwCamp = s.camps.values()[0]
	var home: CwCity = s.cities[&"city.home"]
	var home_food: int = home.food
	assert_int(_play(s, &"card.transport", &"transport",
			{"from_city": &"city.home", "food": 600,
			"target_kind": &"camp", "target_id": camp.id})).is_equal(OK)
	ResolverScript.resolve(s)
	assert_int(home.food).is_equal(home_food - 600 + 120 - 90)
	assert_int(s.convoys.size()).is_equal(1)
	var camp_food: int = camp.food
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_int(s.convoys.size()).is_equal(0)
	assert_int(camp.food).is_equal(camp_food + 600 - 120)
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"convoy_arrived"])


func test_convoy_to_dead_target_loses_food() -> void:
	var s: CwState = _state()
	var a: CwArmy = _only_army(s)
	_play(s, &"card.build_camp", &"build_camp", {"army_id": a.id})
	ResolverScript.resolve(s)
	assert_int(s.camps.size()).is_equal(1)
	if s.camps.size() != 1:
		return
	var camp: CwCamp = s.camps.values()[0]
	_play(s, &"card.transport", &"transport",
			{"from_city": &"city.home", "food": 600,
			"target_kind": &"camp", "target_id": camp.id})
	ResolverScript.resolve(s)
	s.camps.erase(camp.id)
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_int(s.convoys.size()).is_equal(0)
	var delivered := true
	for e: Dictionary in ev:
		if e["t"] == &"convoy_arrived":
			delivered = bool(e["delivered"])
	assert_bool(delivered).is_false()


func test_city_food_reservations_block_transport_and_feast_overdraw() -> void:
	var s: CwState = _state()
	s.register_card(&"card.feast", &"feast", 1)
	s.hand.append(&"card.feast")
	var home: CwCity = s.cities[&"city.home"]
	home.food = 620
	home.victory_cooldown = 2
	var a: CwArmy = _only_army(s)
	assert_int(_play(s, &"card.feast", &"feast",
			{"target_kind": &"city", "target_id": &"city.home"})).is_equal(OK)
	_assert_invalid_atomic(s, &"card.transport", &"transport",
			{"from_city": &"city.home", "food": 600,
			"target_kind": &"army", "target_id": a.id})

	var s2: CwState = _state()
	s2.register_card(&"card.feast", &"feast", 1)
	s2.hand.append(&"card.feast")
	var home2: CwCity = s2.cities[&"city.home"]
	home2.food = 620
	home2.victory_cooldown = 2
	var a2: CwArmy = _only_army(s2)
	assert_int(_play(s2, &"card.transport", &"transport",
			{"from_city": &"city.home", "food": 600,
			"target_kind": &"army", "target_id": a2.id})).is_equal(OK)
	_assert_invalid_atomic(s2, &"card.feast", &"feast",
			{"target_kind": &"city", "target_id": &"city.home"})


func test_transport_rejects_path_step_over_move_points_atomically() -> void:
	var s: CwState = StateScript.new()
	var g: CwMapGrid = GridScript.from_rows(PackedStringArray(["HXH"]), EXPENSIVE_COSTS)
	s.setup(g, TuningScript.new(), 42)
	s.register_card(&"card.transport", &"transport", 1)
	s.add_city(&"city.home", &"player", [Vector2i(0, 0)], 1000, 1000, 0, 1.0)
	var a: CwArmy = ArmyScript.new()
	a.id = s.next_id()
	a.troops = 1000
	a.food = 0
	a.pos = Vector2i(2, 0)
	a.state = &"holding"
	a.hold_left = 99
	a.home_city = &"city.home"
	s.armies[a.id] = a
	s.set_deck([&"card.transport"])
	s.hand = [&"card.transport"]
	s.energy = 10
	_assert_invalid_atomic(s, &"card.transport", &"transport",
			{"from_city": &"city.home", "food": 100,
			"target_kind": &"army", "target_id": a.id})


func test_convoy_delivers_to_stationary_army() -> void:
	var s: CwState = _state()
	var a: CwArmy = _only_army(s)
	a.troops = 1000
	a.food = 100
	a.pos = Vector2i(3, 0)
	a.state = &"holding"
	a.hold_left = 99
	assert_int(_play(s, &"card.transport", &"transport",
			{"from_city": &"city.home", "food": 300,
			"target_kind": &"army", "target_id": a.id})).is_equal(OK)
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_int(s.convoys.size()).is_equal(0)
	assert_int(a.food).is_equal(370)
	var delivered := false
	for e: Dictionary in ev:
		if e["t"] == &"convoy_arrived":
			delivered = bool(e["delivered"])
	assert_bool(delivered).is_true()


func test_convoy_to_moved_army_loses_food() -> void:
	var s: CwState = _state()
	var a: CwArmy = _only_army(s)
	a.troops = 1000
	a.food = 100
	a.pos = Vector2i(3, 0)
	a.state = &"marching"
	a.path = [Vector2i(4, 0), Vector2i(5, 0)]
	assert_int(_play(s, &"card.transport", &"transport",
			{"from_city": &"city.home", "food": 300,
			"target_kind": &"army", "target_id": a.id})).is_equal(OK)
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_int(s.convoys.size()).is_equal(0)
	assert_that(a.pos).is_equal(Vector2i(5, 0))
	assert_int(a.food).is_equal(70)
	var delivered := true
	for e: Dictionary in ev:
		if e["t"] == &"convoy_arrived":
			delivered = bool(e["delivered"])
	assert_bool(delivered).is_false()
