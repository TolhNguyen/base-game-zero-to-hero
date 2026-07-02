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
