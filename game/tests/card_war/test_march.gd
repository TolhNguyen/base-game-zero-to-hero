extends GdUnitTestSuite

const StateScript := preload("res://modules/card_war/sim/cw_state.gd")
const GridScript := preload("res://modules/card_war/sim/cw_map_grid.gd")
const TuningScript := preload("res://modules/card_war/sim/cw_tuning.gd")
const OrderScript := preload("res://modules/card_war/sim/cw_order.gd")
const ResolverScript := preload("res://modules/card_war/sim/cw_resolver.gd")

const COSTS := {"P": 2, "F": 3, "R": 0, "M": 0, "H": 2, "E": 2}
const EXPENSIVE_COSTS := {"H": 2, "X": 7, "E": 2}


func _state() -> CwState:
	var s: CwState = StateScript.new()
	var g: CwMapGrid = GridScript.from_rows(PackedStringArray(["HPPPPE"]), COSTS)
	s.setup(g, TuningScript.new(), 42)
	s.register_card(&"card.march", &"march", 2)
	s.register_general(&"general.asun", 1.0, 0.25)
	var home_tiles: Array[Vector2i] = [Vector2i(0, 0)]
	s.add_city(&"city.home", &"player", home_tiles, 5000, 2000, 40, 1.0)
	var enemy_tiles: Array[Vector2i] = [Vector2i(5, 0)]
	s.add_city(&"city.enemy", &"enemy", enemy_tiles, 1000, 500, 40, 1.5)
	var cards: Array[StringName] = []
	for i: int in range(6):
		cards.append(&"card.march")
	s.set_deck(cards)
	s.energy = 10
	return s


func _play_march(s: CwState, troops: int, to: Vector2i) -> Error:
	var o: CwOrder = OrderScript.new()
	o.card_id = &"card.march"
	o.type = &"march"
	o.params = {"general_id": &"general.asun", "troops": troops,
			"from_city": &"city.home", "to": to}
	return s.play_card(o)


func _order(card: StringName, type: StringName, params: Dictionary) -> CwOrder:
	var o: CwOrder = OrderScript.new()
	o.card_id = card
	o.type = type
	o.params = params
	return o


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


func test_full_march_lifecycle() -> void:
	var s: CwState = _state()
	assert_int(_play_march(s, 2000, Vector2i(4, 0))).is_equal(OK)
	var home: CwCity = s.cities[&"city.home"]

	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_int(home.troops).is_equal(3000)
	assert_int(home.food).is_equal(1640)
	assert_int(s.armies.size()).is_equal(1)
	var a: CwArmy = s.armies.values()[0]
	assert_that(a.pos).is_equal(Vector2i(3, 0))
	assert_str(String(a.state)).is_equal("marching")
	assert_bool(s.is_general_busy(&"general.asun")).is_true()
	assert_int(s.turn).is_equal(2)

	ResolverScript.resolve(s)
	assert_that(a.pos).is_equal(Vector2i(4, 0))
	assert_str(String(a.state)).is_equal("holding")
	assert_int(a.hold_left).is_equal(2)

	ResolverScript.resolve(s)
	assert_int(a.hold_left).is_equal(1)
	ResolverScript.resolve(s)
	assert_str(String(a.state)).is_equal("returning")

	ResolverScript.resolve(s)
	ResolverScript.resolve(s)
	assert_int(s.armies.size()).is_equal(0)
	assert_int(home.troops).is_equal(5000)
	assert_bool(s.is_general_busy(&"general.asun")).is_false()
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"order_started", &"army_moved"])


func test_pending_reservations_block_overdraw() -> void:
	var s: CwState = _state()
	assert_int(_play_march(s, 3000, Vector2i(4, 0))).is_equal(OK)
	assert_int(_play_march(s, 1000, Vector2i(3, 0))).is_equal(ERR_INVALID_PARAMETER)
	s.register_general(&"general.b", 1.0, 0.0)
	var o: CwOrder = OrderScript.new()
	o.card_id = &"card.march"
	o.type = &"march"
	o.params = {"general_id": &"general.b", "troops": 2500,
			"from_city": &"city.home", "to": Vector2i(3, 0)}
	assert_int(s.play_card(o)).is_equal(ERR_INVALID_PARAMETER)


func test_resolve_preserves_unhandled_pending_orders() -> void:
	var s: CwState = _state()
	s.register_card(&"card.gather_food", &"gather_food", 1)
	s.hand.append(&"card.gather_food")
	assert_int(s.play_card(_order(&"card.gather_food", &"gather_food",
			{"city": &"city.home"}))).is_equal(OK)
	assert_int(_play_march(s, 2000, Vector2i(4, 0))).is_equal(OK)

	ResolverScript.resolve(s)

	assert_int(s.armies.size()).is_equal(1)
	assert_int(s.pending.size()).is_equal(1)
	if s.pending.size() > 0:
		assert_str(String(s.pending[0].type)).is_equal("gather_food")


func test_march_rejects_path_step_over_move_points_atomically() -> void:
	var s: CwState = StateScript.new()
	var g: CwMapGrid = GridScript.from_rows(PackedStringArray(["HXE"]), EXPENSIVE_COSTS)
	s.setup(g, TuningScript.new(), 42)
	s.register_card(&"card.march", &"march", 2)
	s.register_general(&"general.asun", 1.0, 0.25)
	var home_tiles: Array[Vector2i] = [Vector2i(0, 0)]
	s.add_city(&"city.home", &"player", home_tiles, 5000, 2000, 40, 1.0)
	var enemy_tiles: Array[Vector2i] = [Vector2i(2, 0)]
	s.add_city(&"city.enemy", &"enemy", enemy_tiles, 1000, 500, 40, 1.5)
	s.set_deck([&"card.march"])
	s.energy = 10

	_assert_invalid_atomic(s, _order(&"card.march", &"march",
			{"general_id": &"general.asun", "troops": 100,
			"from_city": &"city.home", "to": Vector2i(2, 0)}))


func test_returning_army_is_lost_if_home_missing_at_merge() -> void:
	var s: CwState = _state()
	assert_int(_play_march(s, 2000, Vector2i(1, 0))).is_equal(OK)
	ResolverScript.resolve(s)
	var a: CwArmy = s.armies.values()[0]
	ResolverScript.resolve(s)
	ResolverScript.resolve(s)
	assert_str(String(a.state)).is_equal("returning")

	s.cities.erase(&"city.home")
	var ev: Array[Dictionary] = ResolverScript.resolve(s)

	assert_int(s.armies.size()).is_equal(0)
	assert_bool(s.is_general_busy(&"general.asun")).is_false()
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"army_lost"])


func test_no_result_before_turn_limit_and_defeat_on_limit() -> void:
	var s: CwState = _state()
	s.tuning.turn_limit = 3
	ResolverScript.resolve(s)
	assert_str(String(s.result)).is_equal("")
	ResolverScript.resolve(s)
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_str(String(s.result)).is_equal("defeat")
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"defeat"])


func test_resolve_after_result_is_noop() -> void:
	var s: CwState = _state()
	s.result = &"victory"
	var before: int = s.turn
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_int(ev.size()).is_equal(0)
	assert_int(s.turn).is_equal(before)
