extends GdUnitTestSuite

const StateScript := preload("res://modules/card_war/sim/cw_state.gd")
const GridScript := preload("res://modules/card_war/sim/cw_map_grid.gd")
const TuningScript := preload("res://modules/card_war/sim/cw_tuning.gd")
const ResolverScript := preload("res://modules/card_war/sim/cw_resolver.gd")
const ArmyScript := preload("res://modules/card_war/sim/cw_army.gd")
const CampScript := preload("res://modules/card_war/sim/cw_camp.gd")

const COSTS := {"P": 2, "F": 3, "R": 0, "M": 0, "H": 2, "E": 2}


func _state() -> CwState:
	var s: CwState = StateScript.new()
	var g: CwMapGrid = GridScript.from_rows(PackedStringArray(["HPPPPE"]), COSTS)
	s.setup(g, TuningScript.new(), 42)
	var home_tiles: Array[Vector2i] = [Vector2i(0, 0)]
	s.add_city(&"city.home", &"player", home_tiles, 1000, 500, 40, 1.0)
	var enemy_tiles: Array[Vector2i] = [Vector2i(5, 0)]
	s.add_city(&"city.enemy", &"enemy", enemy_tiles, 1000, 500, 40, 1.5)
	return s


func test_city_production_and_consumption() -> void:
	var s: CwState = _state()
	var home: CwCity = s.cities[&"city.home"]
	ResolverScript.resolve(s)
	# +40*3 production, -1000/100*3 consumption = 500 + 120 - 30 = 590
	assert_int(home.food).is_equal(590)
	assert_bool(home.starving).is_false()
	assert_float(home.morale).is_equal_approx(80.0, 0.01)


func test_starving_city_loses_morale_and_surrenders() -> void:
	var s: CwState = _state()
	var home: CwCity = s.cities[&"city.home"]
	home.food = 0
	home.production_per_day = 0
	home.morale = 25.0
	ResolverScript.resolve(s)
	assert_bool(home.starving).is_true()
	assert_float(home.morale).is_equal_approx(15.0, 0.01)
	ResolverScript.resolve(s)
	assert_float(home.morale).is_equal_approx(5.0, 0.01)
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_str(String(home.owner_side)).is_equal("enemy")
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"starving", &"city_surrendered"])
	assert_str(String(s.result)).is_equal("defeat")


func test_starving_army_decays_and_disbands() -> void:
	var s: CwState = _state()
	var a: CwArmy = ArmyScript.new()
	a.id = s.next_id()
	a.general_id = &"general.asun"
	a.troops = 2000
	a.morale = 15.0
	a.food = 0
	a.pos = Vector2i(2, 0)
	a.state = &"holding"
	a.hold_left = 99
	a.home_city = &"city.home"
	s.armies[a.id] = a
	s.set_general_busy(&"general.asun", true)
	ResolverScript.resolve(s)
	assert_float(a.morale).is_equal_approx(5.0, 0.01)
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_int(s.armies.size()).is_equal(0)
	assert_bool(s.is_general_busy(&"general.asun")).is_false()
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"army_disbanded"])


func test_army_consumes_carried_food() -> void:
	var s: CwState = _state()
	var a: CwArmy = ArmyScript.new()
	a.id = s.next_id()
	a.troops = 2000
	a.food = 100
	a.pos = Vector2i(2, 0)
	a.state = &"holding"
	a.hold_left = 99
	s.armies[a.id] = a
	ResolverScript.resolve(s)
	assert_int(a.food).is_equal(40)
	assert_bool(a.starving).is_false()
	ResolverScript.resolve(s)
	assert_int(a.food).is_equal(0)
	assert_bool(a.starving).is_true()


func test_camp_consumes_and_collapses() -> void:
	var s: CwState = _state()
	var c: CwCamp = CampScript.new()
	c.id = s.next_id()
	c.pos = Vector2i(3, 0)
	c.troops = 2000
	c.food = 0
	c.morale = 5.0
	c.general_id = &"general.x"
	s.camps[c.id] = c
	s.set_general_busy(&"general.x", true)
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_int(s.camps.size()).is_equal(0)
	assert_bool(s.is_general_busy(&"general.x")).is_false()
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"camp_lost"])
