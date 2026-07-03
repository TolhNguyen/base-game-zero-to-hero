class_name CwState
extends RefCounted
## Full sim state. Mutated only by play_card() (validated, atomic) and
## CwResolver.resolve(). Deterministic: seeded rng for deck shuffles.

var turn := 1
var energy := 0
var result: StringName = &""  # "" | victory | defeat
var map: CwMapGrid
var tuning: CwTuning

var deck: Array[StringName] = []
var hand: Array[StringName] = []
var discard: Array[StringName] = []

var cities := {}   # StringName -> CwCity
var armies := {}   # int -> CwArmy
var camps := {}    # int -> CwCamp
var convoys := {}  # int -> CwConvoy
var pending: Array[CwOrder] = []

var _cards := {}     # card id -> {"type": StringName, "cost": int}
var _generals := {}  # general id -> {"combat_factor": float, "loss_reduction": float}
var _busy := {}      # general id -> true
var _next_id := 1
var _rng := RandomNumberGenerator.new()


func setup(p_map: CwMapGrid, p_tuning: CwTuning, seed_value: int) -> void:
	map = p_map
	tuning = p_tuning
	energy = tuning.energy_start
	_rng.seed = seed_value


func register_card(id: StringName, order_type: StringName, cost: int) -> void:
	_cards[id] = {"type": order_type, "cost": cost}


func register_general(id: StringName, combat_factor: float, loss_reduction: float) -> void:
	_generals[id] = {"combat_factor": combat_factor, "loss_reduction": loss_reduction}


func has_card(id: StringName) -> bool:
	return _cards.has(id)


func card_cost(id: StringName) -> int:
	return int(_cards[id]["cost"]) if _cards.has(id) else 0


func card_type(id: StringName) -> StringName:
	return StringName(_cards[id]["type"]) if _cards.has(id) else &""


func has_general(id: StringName) -> bool:
	return _generals.has(id)


func general_combat_factor(id: StringName) -> float:
	return float(_generals[id]["combat_factor"]) if _generals.has(id) else 1.0


func general_loss_reduction(id: StringName) -> float:
	return float(_generals[id]["loss_reduction"]) if _generals.has(id) else 0.0


func is_general_busy(id: StringName) -> bool:
	return bool(_busy.get(id, false))


func set_general_busy(id: StringName, busy: bool) -> void:
	if busy:
		_busy[id] = true
	else:
		_busy.erase(id)


func add_city(id: StringName, owner_side: StringName, tiles: Array[Vector2i],
		troops: int, food: int, production: int, wall: float) -> CwCity:
	var c: CwCity = CwCity.new()
	c.id = id
	c.owner_side = owner_side
	c.tiles = tiles
	c.troops = troops
	c.food = food
	c.production_per_day = production
	c.morale = tuning.morale_start
	c.wall_factor = wall
	cities[id] = c
	return c


## Takes the full card list (all copies), shuffles with the seeded rng,
## draws the opening hand.
func set_deck(cards: Array[StringName]) -> void:
	deck = cards.duplicate()
	_shuffle(deck)
	hand.clear()
	discard.clear()
	draw(tuning.opening_hand)


## Draws up to n cards (hand cap; reshuffles discard when the deck runs out).
func draw(n: int) -> Array[StringName]:
	var drawn: Array[StringName] = []
	for i: int in n:
		if hand.size() >= tuning.hand_max:
			break
		if deck.is_empty():
			if discard.is_empty():
				break
			deck = discard.duplicate()
			discard.clear()
			_shuffle(deck)
		var card: StringName = deck.pop_back()
		hand.append(card)
		drawn.append(card)
	return drawn


func play_card(order: CwOrder) -> Error:
	if _validate_order(order) != OK:
		return ERR_INVALID_PARAMETER

	var queued: CwOrder = CwOrder.new()
	queued.card_id = order.card_id
	queued.type = order.type
	queued.params = order.params.duplicate()

	energy -= card_cost(order.card_id)
	hand.erase(order.card_id)
	discard.append(order.card_id)
	pending.append(queued)
	return OK


func spawn_tile(city: CwCity) -> Vector2i:
	return city.anchor()


func march_food_needed(troops: int, path: Array[Vector2i]) -> int:
	var go_turns: int = map.turns_for_path(path, tuning.move_points_per_turn)
	var total_turns: int = go_turns + tuning.march_hold_turns + go_turns
	var food_per_turn: int = ceili(troops / 100.0 * 3.0)
	return food_per_turn * total_turns


func next_id() -> int:
	_next_id += 1
	return _next_id - 1


func army_at(p: Vector2i) -> CwArmy:
	for value: Variant in armies.values():
		var a: CwArmy = value as CwArmy
		if a.pos == p:
			return a
	return null


func camp_at(p: Vector2i) -> CwCamp:
	for value: Variant in camps.values():
		var c: CwCamp = value as CwCamp
		if c.pos == p:
			return c
	return null


func city_at(p: Vector2i) -> CwCity:
	for value: Variant in cities.values():
		var c: CwCity = value as CwCity
		if c.contains(p):
			return c
	return null


func total_player_food() -> int:
	var total := 0
	for value: Variant in cities.values():
		var c: CwCity = value as CwCity
		if c.owner_side == &"player":
			total += c.food
	for value: Variant in camps.values():
		var camp: CwCamp = value as CwCamp
		total += camp.food
	for value: Variant in armies.values():
		var a: CwArmy = value as CwArmy
		total += a.food
	for value: Variant in convoys.values():
		var v: CwConvoy = value as CwConvoy
		total += v.food
	return total


func avg_player_morale() -> float:
	var sum := 0.0
	var n := 0
	for value: Variant in cities.values():
		var c: CwCity = value as CwCity
		if c.owner_side == &"player":
			sum += c.morale
			n += 1
	for value: Variant in camps.values():
		var camp: CwCamp = value as CwCamp
		sum += camp.morale
		n += 1
	for value: Variant in armies.values():
		var a: CwArmy = value as CwArmy
		sum += a.morale
		n += 1
	return sum / n if n > 0 else 0.0


func _shuffle(arr: Array[StringName]) -> void:
	for i: int in range(arr.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp: StringName = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func _validate_order(order: CwOrder) -> Error:
	if order == null:
		return ERR_INVALID_PARAMETER
	if result != &"":
		return ERR_INVALID_PARAMETER
	if not has_card(order.card_id):
		return ERR_INVALID_PARAMETER
	if not hand.has(order.card_id):
		return ERR_INVALID_PARAMETER
	if order.type != card_type(order.card_id):
		return ERR_INVALID_PARAMETER
	if energy < card_cost(order.card_id):
		return ERR_INVALID_PARAMETER

	match order.type:
		&"march":
			return _validate_march(order.params)
		&"gather_food":
			return _validate_gather_food(order.params)
		&"build_camp":
			return _validate_build_camp(order.params)
		&"transport":
			return _validate_transport(order.params)
		&"assault":
			return _validate_assault(order.params)
		&"feast":
			return _validate_feast(order.params)
		_:
			return ERR_INVALID_PARAMETER


func _validate_march(params: Dictionary) -> Error:
	var from_city_id: StringName = StringName(params.get("from_city", &""))
	var city: CwCity = _player_city(from_city_id)
	if city == null:
		return ERR_INVALID_PARAMETER

	var general_id: StringName = StringName(params.get("general_id", &""))
	if not has_general(general_id) or is_general_busy(general_id):
		return ERR_INVALID_PARAMETER

	var troops: int = int(params.get("troops", 0))
	if troops < 1 or troops > city.troops:
		return ERR_INVALID_PARAMETER

	var to: Vector2i = params.get("to", Vector2i.ZERO) as Vector2i
	var path: Array[Vector2i] = map.find_path(spawn_tile(city), to)
	if path.is_empty():
		return ERR_INVALID_PARAMETER
	if city.food < march_food_needed(troops, path):
		return ERR_INVALID_PARAMETER
	return OK


func _validate_gather_food(params: Dictionary) -> Error:
	var city_id: StringName = StringName(params.get("city", &""))
	return OK if _player_city(city_id) != null else ERR_INVALID_PARAMETER


func _validate_build_camp(params: Dictionary) -> Error:
	var army_id: int = int(params.get("army_id", 0))
	var army: CwArmy = armies.get(army_id, null) as CwArmy
	if army == null or army.state == &"returning":
		return ERR_INVALID_PARAMETER
	return OK


func _validate_transport(params: Dictionary) -> Error:
	var from_city_id: StringName = StringName(params.get("from_city", &""))
	var city: CwCity = _player_city(from_city_id)
	if city == null:
		return ERR_INVALID_PARAMETER

	var food: int = int(params.get("food", 0))
	if food < 1 or food > city.food:
		return ERR_INVALID_PARAMETER

	var target_kind: StringName = StringName(params.get("target_kind", &""))
	if target_kind != &"camp" and target_kind != &"army":
		return ERR_INVALID_PARAMETER

	var found: bool = false
	var target_pos: Vector2i = Vector2i.ZERO
	var target_id: Variant = params.get("target_id", 0)
	if target_kind == &"camp":
		var camp: CwCamp = camps.get(int(target_id), null) as CwCamp
		if camp != null:
			found = true
			target_pos = camp.pos
	else:
		var army: CwArmy = armies.get(int(target_id), null) as CwArmy
		if army != null:
			found = true
			target_pos = army.pos
	if not found:
		return ERR_INVALID_PARAMETER

	var start: Vector2i = spawn_tile(city)
	var path: Array[Vector2i] = map.find_path(start, target_pos)
	if path.is_empty() and start != target_pos:
		return ERR_INVALID_PARAMETER
	return OK


func _validate_assault(params: Dictionary) -> Error:
	var army_id: int = int(params.get("army_id", 0))
	var army: CwArmy = armies.get(army_id, null) as CwArmy
	if army == null or army.state != &"holding":
		return ERR_INVALID_PARAMETER

	var city_id: StringName = StringName(params.get("city", &""))
	var city: CwCity = _enemy_city(city_id)
	if city == null:
		return ERR_INVALID_PARAMETER
	if not _is_adjacent_to_city(army.pos, city):
		return ERR_INVALID_PARAMETER
	return OK


func _validate_feast(params: Dictionary) -> Error:
	var target_kind: StringName = StringName(params.get("target_kind", &""))
	var target_id: Variant = params.get("target_id", 0)
	var troops: int = 0
	var food: int = 0
	var victory_cooldown: int = 0

	if target_kind == &"army":
		var army: CwArmy = armies.get(int(target_id), null) as CwArmy
		if army == null:
			return ERR_INVALID_PARAMETER
		troops = army.troops
		food = army.food
		victory_cooldown = army.victory_cooldown
	elif target_kind == &"city":
		var city: CwCity = _player_city(StringName(target_id))
		if city == null:
			return ERR_INVALID_PARAMETER
		troops = city.troops
		food = city.food
		victory_cooldown = city.victory_cooldown
	else:
		return ERR_INVALID_PARAMETER

	var one_day_ration: int = ceili(troops / 100.0)
	if victory_cooldown <= 0 or food < one_day_ration:
		return ERR_INVALID_PARAMETER
	return OK


func _player_city(id: StringName) -> CwCity:
	var city: CwCity = cities.get(id, null) as CwCity
	if city == null or city.owner_side != &"player":
		return null
	return city


func _enemy_city(id: StringName) -> CwCity:
	var city: CwCity = cities.get(id, null) as CwCity
	if city == null or city.owner_side == &"player":
		return null
	return city


func _is_adjacent_to_city(pos: Vector2i, city: CwCity) -> bool:
	for tile: Vector2i in city.tiles:
		var delta: Vector2i = tile - pos
		if abs(delta.x) + abs(delta.y) == 1:
			return true
	return false
