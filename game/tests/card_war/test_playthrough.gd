extends GdUnitTestSuite
## Integration: builds the real tutorial scenario from res://content and
## plays a scripted winning line. Hand is stuffed explicitly before each
## play so the seeded shuffle can never starve the script of cards.

const BuilderScript := preload("res://modules/card_war/sim/cw_builder.gd")
const OrderScript := preload("res://modules/card_war/sim/cw_order.gd")
const ResolverScript := preload("res://modules/card_war/sim/cw_resolver.gd")


func _build() -> CwState:
	var scenario: CwScenarioDef = load("res://content/scenarios/scenario.tutorial_01.tres")
	var map_def: CwMapDef = load("res://content/maps/map.tutorial_01.tres")
	var terrains: Array[CwTerrainDef] = []
	for f: String in ["plains", "forest", "river", "mountain", "city_home", "city_enemy"]:
		terrains.append(load("res://content/terrains/terrain.%s.tres" % f))
	var cards: Array[CwCardDef] = []
	for f: String in ["march", "gather_food", "build_camp", "transport", "assault", "feast"]:
		cards.append(load("res://content/cards/card.%s.tres" % f))
	var generals: Array[CwGeneralDef] = []
	generals.append(load("res://content/generals/general.asun.tres"))
	return BuilderScript.build(scenario, map_def, terrains, cards, generals, 42)


func _force_hand(s: CwState, card: StringName) -> void:
	if not s.hand.has(card):
		s.hand.append(card)


func _play(s: CwState, card: StringName, type: StringName, params: Dictionary) -> Error:
	_force_hand(s, card)
	var o: CwOrder = OrderScript.new()
	o.card_id = card
	o.type = type
	o.params = params
	return s.play_card(o)


func test_builder_wires_scenario() -> void:
	var s: CwState = _build()
	var expected_cards := {
		&"card.march": {"count": 3, "cost": 2, "type": &"march"},
		&"card.gather_food": {"count": 3, "cost": 1, "type": &"gather_food"},
		&"card.build_camp": {"count": 3, "cost": 1, "type": &"build_camp"},
		&"card.transport": {"count": 3, "cost": 1, "type": &"transport"},
		&"card.assault": {"count": 3, "cost": 3, "type": &"assault"},
		&"card.feast": {"count": 3, "cost": 1, "type": &"feast"},
	}
	var all_cards: Array[StringName] = []
	all_cards.append_array(s.deck)
	all_cards.append_array(s.hand)
	var card_counts := {}
	for card: StringName in all_cards:
		card_counts[card] = int(card_counts.get(card, 0)) + 1
	assert_int(all_cards.size()).is_equal(18)
	for card_id: StringName in expected_cards:
		var expected: Dictionary = expected_cards[card_id]
		assert_int(int(card_counts.get(card_id, 0)))\
			.override_failure_message("wrong count for %s" % card_id)\
			.is_equal(int(expected["count"]))
		assert_int(s.card_cost(card_id)).is_equal(int(expected["cost"]))
		assert_str(String(s.card_type(card_id))).is_equal(String(expected["type"]))
	assert_that(s.map.size).is_equal(Vector2i(16, 16))
	assert_int(s.cities.size()).is_equal(2)
	var home: CwCity = s.cities[&"city.home"]
	assert_int(home.troops).is_equal(5000)
	assert_int(home.food).is_equal(2000)
	assert_int(home.tiles.size()).is_equal(4)
	assert_that(home.anchor()).is_equal(Vector2i(7, 13))
	var enemy: CwCity = s.cities[&"city.enemy"]
	assert_int(enemy.troops).is_equal(1000)
	assert_that(enemy.tiles).is_equal([Vector2i(8, 2)] as Array[Vector2i])
	assert_int(s.deck.size() + s.hand.size()).is_equal(18)
	assert_int(s.hand.size()).is_equal(5)
	assert_int(s.energy).is_equal(3)
	assert_bool(s.has_general(&"general.asun")).is_true()
	assert_float(s.general_combat_factor(&"general.asun")).is_equal_approx(1.0, 0.01)
	assert_float(s.general_loss_reduction(&"general.asun")).is_equal_approx(0.25, 0.01)


func test_scripted_win_in_seven_turns() -> void:
	var s: CwState = _build()
	var home: CwCity = s.cities[&"city.home"]
	var enemy: CwCity = s.cities[&"city.enemy"]
	assert_int(_play(s, &"card.march", &"march",
			{"general_id": &"general.asun", "troops": 4000,
			"from_city": &"city.home", "to": Vector2i(8, 3)})).is_equal(OK)
	ResolverScript.resolve(s)
	assert_int(s.armies.size()).is_equal(1)
	var a: CwArmy = s.armies.values()[0]
	assert_int(home.troops).is_equal(1000)
	for i: int in 4:
		ResolverScript.resolve(s)
	assert_that(a.pos).is_equal(Vector2i(8, 3))
	assert_str(String(a.state)).is_equal("holding")
	assert_int(s.turn).is_equal(6)
	assert_int(_play(s, &"card.assault", &"assault",
			{"army_id": a.id, "city": &"city.enemy"})).is_equal(OK)
	ResolverScript.resolve(s)
	assert_int(enemy.troops).is_equal(200)
	assert_str(String(enemy.owner_side)).is_equal("enemy")
	assert_int(_play(s, &"card.assault", &"assault",
			{"army_id": a.id, "city": &"city.enemy"})).is_equal(OK)
	ResolverScript.resolve(s)
	assert_str(String(enemy.owner_side)).is_equal("player")
	assert_str(String(s.result)).is_equal("victory")
	assert_int(s.turn).is_equal(7)
	assert_int(home.food).is_equal(1190)
