extends GdUnitTestSuite

const StateScript := preload("res://modules/card_war/sim/cw_state.gd")
const GridScript := preload("res://modules/card_war/sim/cw_map_grid.gd")
const TuningScript := preload("res://modules/card_war/sim/cw_tuning.gd")

const COSTS := {"P": 2, "F": 3, "R": 0, "M": 0, "H": 2, "E": 2}


func _state() -> CwState:
	var s: CwState = StateScript.new()
	var g: CwMapGrid = GridScript.from_rows(PackedStringArray(["HPPE", "PPPP"]), COSTS)
	var t: CwTuning = TuningScript.new()
	s.setup(g, t, 42)
	s.register_card(&"card.march", &"march", 2)
	s.register_card(&"card.gather_food", &"gather_food", 1)
	return s


func test_setup_defaults() -> void:
	var s: CwState = _state()
	assert_int(s.turn).is_equal(1)
	assert_int(s.energy).is_equal(3)
	assert_str(String(s.result)).is_equal("")


func test_card_registry_helpers() -> void:
	var s: CwState = _state()
	assert_bool(s.has_card(&"card.march")).is_true()
	assert_int(s.card_cost(&"card.march")).is_equal(2)
	assert_str(String(s.card_type(&"card.march"))).is_equal("march")
	assert_bool(s.has_card(&"card.gather_food")).is_true()
	assert_int(s.card_cost(&"card.gather_food")).is_equal(1)
	assert_str(String(s.card_type(&"card.gather_food"))).is_equal("gather_food")
	assert_bool(s.has_card(&"card.unknown")).is_false()
	assert_int(s.card_cost(&"card.unknown")).is_equal(0)
	assert_str(String(s.card_type(&"card.unknown"))).is_equal("")


func test_general_registry_and_busy_helpers() -> void:
	var s: CwState = _state()
	assert_bool(s.has_general(&"general.unknown")).is_false()
	assert_float(s.general_combat_factor(&"general.unknown")).is_equal_approx(1.0, 0.001)
	assert_float(s.general_loss_reduction(&"general.unknown")).is_equal_approx(0.0, 0.001)
	assert_bool(s.is_general_busy(&"general.asun")).is_false()

	s.register_general(&"general.asun", 1.5, 0.25)
	assert_bool(s.has_general(&"general.asun")).is_true()
	assert_float(s.general_combat_factor(&"general.asun")).is_equal_approx(1.5, 0.001)
	assert_float(s.general_loss_reduction(&"general.asun")).is_equal_approx(0.25, 0.001)
	s.set_general_busy(&"general.asun", true)
	assert_bool(s.is_general_busy(&"general.asun")).is_true()
	s.set_general_busy(&"general.asun", false)
	assert_bool(s.is_general_busy(&"general.asun")).is_false()


func test_deck_shuffle_is_seeded_and_opening_hand_drawn() -> void:
	var cards: Array[StringName] = []
	for i: int in 9:
		cards.append(&"card.march" if i % 2 == 0 else &"card.gather_food")
	var s1: CwState = _state()
	s1.set_deck(cards.duplicate())
	var s2: CwState = _state()
	s2.set_deck(cards.duplicate())
	assert_that(s1.hand).is_equal(s2.hand)
	assert_int(s1.hand.size()).is_equal(5)
	assert_int(s1.deck.size()).is_equal(4)


func test_draw_respects_hand_cap_and_reshuffles_discard() -> void:
	var cards: Array[StringName] = []
	for i: int in 6:
		cards.append(&"card.march")
	var s: CwState = _state()
	s.tuning.hand_max = 6
	s.set_deck(cards)
	assert_int(s.hand.size()).is_equal(5)
	s.discard.append(&"card.gather_food")
	var drawn: Array[StringName] = s.draw(3)
	assert_int(drawn.size()).is_equal(1)
	assert_int(s.hand.size()).is_equal(6)
	s.hand.clear()
	var drawn2: Array[StringName] = s.draw(2)  # deck empty -> reshuffle discard
	assert_int(drawn2.size()).is_equal(1)
	assert_bool(s.deck.is_empty()).is_true()
	assert_bool(s.discard.is_empty()).is_true()
	assert_int(s.hand.size()).is_equal(1)


func test_next_id_army_at_and_camp_at() -> void:
	var s: CwState = _state()
	assert_int(s.next_id()).is_equal(1)
	assert_int(s.next_id()).is_equal(2)

	var a: CwArmy = CwArmy.new()
	a.id = s.next_id()
	a.pos = Vector2i(2, 0)
	s.armies[a.id] = a
	var camp: CwCamp = CwCamp.new()
	camp.id = s.next_id()
	camp.pos = Vector2i(1, 1)
	s.camps[camp.id] = camp

	assert_that(s.army_at(Vector2i(2, 0))).is_same(a)
	assert_that(s.army_at(Vector2i(1, 1))).is_null()
	assert_that(s.camp_at(Vector2i(1, 1))).is_same(camp)
	assert_that(s.camp_at(Vector2i(2, 0))).is_null()


func test_city_and_lookups() -> void:
	var s: CwState = _state()
	var tiles: Array[Vector2i] = [Vector2i(0, 0)]
	var c: CwCity = s.add_city(&"city.home", &"player", tiles, 5000, 2000, 40, 1.0)
	assert_that(s.city_at(Vector2i(0, 0))).is_same(c)
	assert_that(c.anchor()).is_equal(Vector2i(0, 0))
	assert_int(c.food_per_turn()).is_equal(150)
	assert_float(s.avg_player_morale()).is_equal_approx(80.0, 0.01)
	assert_int(s.total_player_food()).is_equal(2000)


func test_total_food_and_average_morale_include_player_entities() -> void:
	var s: CwState = _state()
	var player_tiles: Array[Vector2i] = [Vector2i(0, 0)]
	var enemy_tiles: Array[Vector2i] = [Vector2i(3, 0)]
	var player_city: CwCity = s.add_city(&"city.home", &"player", player_tiles, 5000, 100, 40, 1.0)
	var enemy_city: CwCity = s.add_city(&"city.enemy", &"enemy", enemy_tiles, 1000, 999, 40, 1.5)
	player_city.morale = 80.0
	enemy_city.morale = 5.0

	var camp: CwCamp = CwCamp.new()
	camp.id = s.next_id()
	camp.food = 20
	camp.morale = 70.0
	s.camps[camp.id] = camp

	var army: CwArmy = CwArmy.new()
	army.id = s.next_id()
	army.food = 30
	army.morale = 50.0
	s.armies[army.id] = army

	var convoy: CwConvoy = CwConvoy.new()
	convoy.id = s.next_id()
	convoy.food = 40
	s.convoys[convoy.id] = convoy

	assert_int(s.total_player_food()).is_equal(190)
	assert_float(s.avg_player_morale()).is_equal_approx(200.0 / 3.0, 0.01)
