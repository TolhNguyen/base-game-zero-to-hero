extends GdUnitTestSuite

const StateScript := preload("res://modules/card_war/sim/cw_state.gd")
const GridScript := preload("res://modules/card_war/sim/cw_map_grid.gd")
const TuningScript := preload("res://modules/card_war/sim/cw_tuning.gd")
const OrderScript := preload("res://modules/card_war/sim/cw_order.gd")
const ArmyScript := preload("res://modules/card_war/sim/cw_army.gd")
const CampScript := preload("res://modules/card_war/sim/cw_camp.gd")

const COSTS := {"P": 2, "F": 3, "R": 0, "M": 0, "H": 2, "E": 2}


func _state() -> CwState:
	var s: CwState = StateScript.new()
	var g: CwMapGrid = GridScript.from_rows(PackedStringArray(["HPPPE", "PPPPP"]), COSTS)
	s.setup(g, TuningScript.new(), 42)
	s.register_card(&"card.march", &"march", 2)
	s.register_card(&"card.gather_food", &"gather_food", 1)
	s.register_card(&"card.build_camp", &"build_camp", 1)
	s.register_card(&"card.transport", &"transport", 1)
	s.register_card(&"card.assault", &"assault", 3)
	s.register_card(&"card.feast", &"feast", 1)
	s.register_general(&"general.asun", 1.0, 0.25)
	var home_tiles: Array[Vector2i] = [Vector2i(0, 0)]
	s.add_city(&"city.home", &"player", home_tiles, 5000, 2000, 40, 1.0)
	var enemy_tiles: Array[Vector2i] = [Vector2i(4, 0)]
	s.add_city(&"city.enemy", &"enemy", enemy_tiles, 1000, 500, 40, 1.5)
	var cards: Array[StringName] = [&"card.march", &"card.gather_food", &"card.build_camp",
			&"card.transport", &"card.assault", &"card.feast"]
	s.set_deck(cards)
	s.hand = cards.duplicate()
	s.energy = 10
	return s


func _order(card: StringName, type: StringName, params: Dictionary) -> CwOrder:
	var o: CwOrder = OrderScript.new()
	o.card_id = card
	o.type = type
	o.params = params
	return o


func _add_holding_army(s: CwState, pos: Vector2i = Vector2i(3, 0)) -> CwArmy:
	var a: CwArmy = ArmyScript.new()
	a.id = s.next_id()
	a.general_id = &"general.asun"
	a.troops = 2000
	a.food = 500
	a.morale = 80.0
	a.pos = pos
	a.state = &"holding"
	a.home_city = &"city.home"
	s.armies[a.id] = a
	s.set_general_busy(&"general.asun", true)
	return a


func _assert_invalid_atomic(s: CwState, order: CwOrder) -> void:
	var hand_before: Array[StringName] = s.hand.duplicate()
	var discard_before: Array[StringName] = s.discard.duplicate()
	var energy_before: int = s.energy
	var pending_before: int = s.pending.size()
	assert_int(s.play_card(order)).is_equal(ERR_INVALID_PARAMETER)
	assert_that(s.hand).is_equal(hand_before)
	assert_that(s.discard).is_equal(discard_before)
	assert_int(s.energy).is_equal(energy_before)
	assert_int(s.pending.size()).is_equal(pending_before)


func test_play_card_queues_order_spends_energy_and_moves_card_to_discard() -> void:
	var s: CwState = _state()
	var order: CwOrder = _order(&"card.gather_food", &"gather_food", {"city": &"city.home"})
	var err: Error = s.play_card(order)
	order.params["city"] = &"city.enemy"
	assert_int(err).is_equal(OK)
	assert_int(s.energy).is_equal(9)
	assert_bool(s.hand.has(&"card.gather_food")).is_false()
	assert_that(s.discard).contains([&"card.gather_food"])
	assert_int(s.pending.size()).is_equal(1)
	assert_str(String(s.pending[0].card_id)).is_equal("card.gather_food")
	assert_str(String(s.pending[0].type)).is_equal("gather_food")
	assert_str(String(s.pending[0].params["city"])).is_equal("city.home")


func test_common_validation_rejections_are_atomic() -> void:
	var finished: CwState = _state()
	finished.result = &"victory"
	_assert_invalid_atomic(finished, _order(&"card.gather_food", &"gather_food", {"city": &"city.home"}))

	var unregistered: CwState = _state()
	_assert_invalid_atomic(unregistered, _order(&"card.unknown", &"gather_food", {"city": &"city.home"}))

	var not_in_hand: CwState = _state()
	not_in_hand.hand.erase(&"card.gather_food")
	_assert_invalid_atomic(not_in_hand, _order(&"card.gather_food", &"gather_food", {"city": &"city.home"}))

	var wrong_type: CwState = _state()
	_assert_invalid_atomic(wrong_type, _order(&"card.gather_food", &"march", {"city": &"city.home"}))

	var tired: CwState = _state()
	tired.energy = 0
	_assert_invalid_atomic(tired, _order(&"card.gather_food", &"gather_food", {"city": &"city.home"}))


func test_rejected_order_is_atomic() -> void:
	var s: CwState = _state()
	var hand_before: Array[StringName] = s.hand.duplicate()
	var discard_before: Array[StringName] = s.discard.duplicate()
	var energy_before: int = s.energy
	var pending_before: int = s.pending.size()
	var err: Error = s.play_card(_order(&"card.march", &"march",
			{"general_id": &"general.asun", "troops": 99999,
			"from_city": &"city.home", "to": Vector2i(3, 0)}))
	assert_int(err).is_equal(ERR_INVALID_PARAMETER)
	assert_that(s.hand).is_equal(hand_before)
	assert_that(s.discard).is_equal(discard_before)
	assert_int(s.energy).is_equal(energy_before)
	assert_int(s.pending.size()).is_equal(pending_before)


func test_march_validation_and_food_budget() -> void:
	var s: CwState = _state()
	var path: Array[Vector2i] = s.map.find_path(Vector2i(0, 0), Vector2i(3, 0))
	assert_int(s.march_food_needed(2000, path)).is_equal(240)
	assert_int(s.play_card(_order(&"card.march", &"march",
			{"general_id": &"general.asun", "troops": 2000,
			"from_city": &"city.home", "to": Vector2i(3, 0)}))).is_equal(OK)

	var s2: CwState = _state()
	var home: CwCity = s2.cities[&"city.home"]
	home.food = 100
	assert_int(s2.play_card(_order(&"card.march", &"march",
			{"general_id": &"general.asun", "troops": 2000,
			"from_city": &"city.home", "to": Vector2i(3, 0)}))).is_equal(ERR_INVALID_PARAMETER)


func test_transport_and_build_camp_validate_targets() -> void:
	var s: CwState = _state()
	var camp: CwCamp = CampScript.new()
	camp.id = s.next_id()
	camp.pos = Vector2i(2, 1)
	camp.food = 0
	s.camps[camp.id] = camp
	assert_int(s.play_card(_order(&"card.transport", &"transport",
			{"from_city": &"city.home", "food": 300,
			"target_kind": &"camp", "target_id": camp.id}))).is_equal(OK)

	var s2: CwState = _state()
	var returning: CwArmy = _add_holding_army(s2)
	returning.state = &"returning"
	assert_int(s2.play_card(_order(&"card.build_camp", &"build_camp",
			{"army_id": returning.id}))).is_equal(ERR_INVALID_PARAMETER)

	var s3: CwState = _state()
	assert_int(s3.play_card(_order(&"card.transport", &"transport",
			{"from_city": &"city.home", "food": 300,
			"target_kind": &"army", "target_id": 999}))).is_equal(ERR_INVALID_PARAMETER)

	var s4: CwState = _state()
	var over_food_target: CwArmy = _add_holding_army(s4)
	assert_int(s4.play_card(_order(&"card.transport", &"transport",
			{"from_city": &"city.home", "food": 99999,
			"target_kind": &"army", "target_id": over_food_target.id}))).is_equal(ERR_INVALID_PARAMETER)


func test_assault_requires_holding_adjacent_army_and_enemy_city() -> void:
	var s: CwState = _state()
	var a: CwArmy = _add_holding_army(s, Vector2i(3, 0))
	assert_int(s.play_card(_order(&"card.assault", &"assault",
			{"army_id": a.id, "city": &"city.enemy"}))).is_equal(OK)

	var s2: CwState = _state()
	var far: CwArmy = _add_holding_army(s2, Vector2i(1, 1))
	assert_int(s2.play_card(_order(&"card.assault", &"assault",
			{"army_id": far.id, "city": &"city.enemy"}))).is_equal(ERR_INVALID_PARAMETER)


func test_feast_requires_recent_victory_and_food() -> void:
	var s: CwState = _state()
	var a: CwArmy = _add_holding_army(s)
	assert_int(s.play_card(_order(&"card.feast", &"feast",
			{"target_kind": &"army", "target_id": a.id}))).is_equal(ERR_INVALID_PARAMETER)
	a.victory_cooldown = 2
	a.food = 19
	assert_int(s.play_card(_order(&"card.feast", &"feast",
			{"target_kind": &"army", "target_id": a.id}))).is_equal(ERR_INVALID_PARAMETER)
	a.food = 20_000
	assert_int(s.play_card(_order(&"card.feast", &"feast",
			{"target_kind": &"army", "target_id": a.id}))).is_equal(OK)
