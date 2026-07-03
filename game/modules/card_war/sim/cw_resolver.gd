class_name CwResolver
extends RefCounted
## End-of-turn resolution. Seven fixed phases (design doc, in this order):
## 1 start orders, 2 movement, 3 combat, 4 production, 5 consumption,
## 6 morale, 7 win/lose. Then turn++, energy regen, card draw.
## All mutations append an event record {"t": StringName, ...} for the UI.

const CombatScript := preload("res://modules/card_war/sim/cw_combat.gd")


static func resolve(s: CwState) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if s.result != &"":
		return events

	_start_orders(s, events)
	_movement(s, events)
	_combat(s, events)
	_production(s, events)
	_consumption(s, events)
	_morale(s, events)
	_endcheck(s, events)

	if s.result == &"":
		s.turn += 1
		s.energy = mini(s.energy + s.tuning.energy_per_turn, s.tuning.energy_max)
		s.draw(s.tuning.draw_per_turn)
	events.append({"t": &"turn_ended", "turn": s.turn})
	return events


static func _start_orders(s: CwState, events: Array[Dictionary]) -> void:
	var remaining: Array[CwOrder] = []
	for order: CwOrder in s.pending:
		match order.type:
			&"march":
				_start_march(s, order, events)
			&"gather_food":
				_start_gather_food(s, order, events)
			&"assault":
				var army_id: int = int(order.params.get("army_id", 0))
				var army: CwArmy = s.armies.get(army_id, null) as CwArmy
				if army != null and army.assault_city == &"":
					army.assault_city = StringName(order.params.get("city", &""))
			&"feast":
				_start_feast(s, order, events)
			_:
				remaining.append(order)
	s.pending = remaining


static func _start_gather_food(s: CwState, order: CwOrder, events: Array[Dictionary]) -> void:
	var city_id: StringName = StringName(order.params.get("city", &""))
	var city: CwCity = s.cities.get(city_id, null) as CwCity
	if city == null:
		return

	var amount: int = city.production_per_day * 3
	city.food += amount
	events.append({"t": &"food_gathered", "city": city.id, "amount": amount})


static func _start_march(s: CwState, order: CwOrder, events: Array[Dictionary]) -> void:
	var from_city_id: StringName = StringName(order.params.get("from_city", &""))
	var city: CwCity = s.cities.get(from_city_id, null) as CwCity
	if city == null:
		return

	var to: Vector2i = order.params.get("to", Vector2i.ZERO) as Vector2i
	var path: Array[Vector2i] = s.map.find_path(s.spawn_tile(city), to)
	if path.is_empty():
		return

	var troops: int = int(order.params.get("troops", 0))
	var food: int = s.march_food_needed(troops, path)
	city.troops -= troops
	city.food -= food

	var general_id: StringName = StringName(order.params.get("general_id", &""))
	var a: CwArmy = CwArmy.new()
	a.id = s.next_id()
	a.general_id = general_id
	a.general_combat_factor = s.general_combat_factor(general_id)
	a.general_loss_reduction = s.general_loss_reduction(general_id)
	a.troops = troops
	a.morale = s.tuning.morale_start
	a.food = food
	a.pos = s.spawn_tile(city)
	a.state = &"marching"
	a.path = path.duplicate()
	a.hold_left = s.tuning.march_hold_turns
	a.home_city = from_city_id
	s.armies[a.id] = a
	s.set_general_busy(general_id, true)
	events.append({"t": &"order_started", "type": &"march", "army": a.id})


static func _start_feast(s: CwState, order: CwOrder, events: Array[Dictionary]) -> void:
	var target_kind: StringName = StringName(order.params.get("target_kind", &""))
	if target_kind == &"army":
		var army_id: int = int(order.params.get("target_id", 0))
		var army: CwArmy = s.armies.get(army_id, null) as CwArmy
		if army == null:
			return
		var one_day_ration: int = ceili(army.troops / 100.0)
		if army.victory_cooldown <= 0 or army.food < one_day_ration:
			return
		army.food = maxi(0, army.food - one_day_ration)
		army.morale = minf(100.0, army.morale + s.tuning.feast_morale_gain)
		army.victory_cooldown = 0
		events.append({"t": &"feast_held", "kind": &"army", "id": army.id})
	elif target_kind == &"city":
		var city_id: StringName = StringName(order.params.get("target_id", &""))
		var city: CwCity = s.cities.get(city_id, null) as CwCity
		if city == null or city.owner_side != &"player":
			return
		var one_day_ration: int = ceili(city.troops / 100.0)
		if city.victory_cooldown <= 0 or city.food < one_day_ration:
			return
		city.food = maxi(0, city.food - one_day_ration)
		city.morale = minf(100.0, city.morale + s.tuning.feast_morale_gain)
		city.victory_cooldown = 0
		events.append({"t": &"feast_held", "kind": &"city", "id": city.id})


static func _movement(s: CwState, events: Array[Dictionary]) -> void:
	var holding_ids: Array[int] = []
	var moving_ids: Array[int] = []
	for value: Variant in s.armies.values():
		var a: CwArmy = value as CwArmy
		if a.state == &"holding":
			holding_ids.append(a.id)
		elif a.state == &"marching" or a.state == &"returning":
			moving_ids.append(a.id)

	for id: int in moving_ids:
		var a: CwArmy = s.armies.get(id, null) as CwArmy
		if a == null:
			continue
		_move_army(s, a, events)

	for id: int in holding_ids:
		var a: CwArmy = s.armies.get(id, null) as CwArmy
		if a == null or a.state != &"holding" or a.assault_city != &"":
			continue
		a.hold_left -= 1
		if a.hold_left <= 0:
			_begin_return(s, a, events)


static func _move_army(s: CwState, a: CwArmy, events: Array[Dictionary]) -> void:
	var points_left: int = s.tuning.move_points_per_turn
	var moved := false
	while not a.path.is_empty():
		var next: Vector2i = a.path[0]
		var cost: int = s.map.move_cost(next)
		if cost <= 0 or points_left < cost:
			break
		points_left -= cost
		a.pos = next
		a.path.remove_at(0)
		moved = true

	if moved:
		events.append({"t": &"army_moved", "id": a.id, "pos": a.pos})

	if a.path.is_empty():
		if a.state == &"marching":
			a.state = &"holding"
			a.hold_left = s.tuning.march_hold_turns
			events.append({"t": &"army_arrived", "id": a.id, "pos": a.pos})
		elif a.state == &"returning":
			_merge_returned_army(s, a, events)


static func _begin_return(s: CwState, a: CwArmy, events: Array[Dictionary]) -> void:
	var home: CwCity = s.cities.get(a.home_city, null) as CwCity
	if home == null:
		_lose_orphan_army(s, a, events)
		return

	var home_pos: Vector2i = s.spawn_tile(home)
	if a.pos == home_pos:
		_merge_returned_army(s, a, events)
		return

	var path: Array[Vector2i] = s.map.find_path(a.pos, home_pos)
	if path.is_empty():
		a.hold_left = 1
		return

	a.state = &"returning"
	a.path = path
	events.append({"t": &"army_returning", "id": a.id})


static func _merge_returned_army(s: CwState, a: CwArmy, events: Array[Dictionary]) -> void:
	var home: CwCity = s.cities.get(a.home_city, null) as CwCity
	if home == null:
		_lose_orphan_army(s, a, events)
		return

	home.troops += a.troops
	home.food += a.food
	s.set_general_busy(a.general_id, false)
	s.armies.erase(a.id)
	events.append({"t": &"army_returned", "id": a.id})


static func _lose_orphan_army(s: CwState, a: CwArmy, events: Array[Dictionary]) -> void:
	s.set_general_busy(a.general_id, false)
	s.armies.erase(a.id)
	events.append({"t": &"army_lost", "id": a.id, "reason": &"home_missing"})


static func _combat(s: CwState, events: Array[Dictionary]) -> void:
	for value: Variant in s.armies.values():
		var army: CwArmy = value as CwArmy
		if army.victory_cooldown > 0:
			army.victory_cooldown -= 1
	for value: Variant in s.cities.values():
		var cooldown_city: CwCity = value as CwCity
		if cooldown_city.victory_cooldown > 0:
			cooldown_city.victory_cooldown -= 1

	for value: Variant in s.armies.values().duplicate():
		var army: CwArmy = value as CwArmy
		if army.assault_city == &"":
			continue
		var target_city_id: StringName = army.assault_city
		army.assault_city = &""

		var city: CwCity = s.cities.get(target_city_id, null) as CwCity
		if city == null or city.owner_side != &"enemy":
			continue

		var result: Dictionary = CombatScript.assault(army, city)
		var att_losses: int = int(result["att_losses"])
		var def_losses: int = int(result["def_losses"])
		army.troops = maxi(0, army.troops - att_losses)
		city.troops = maxi(0, city.troops - def_losses)

		var captured: bool = bool(result["captured"])
		if bool(result["won"]):
			army.morale = minf(100.0, army.morale + s.tuning.victory_morale_gain)
			city.morale = maxf(0.0, city.morale - s.tuning.defeat_morale_loss)
			if city.troops <= 0 or city.morale <= 0.0:
				captured = true
		else:
			army.morale = maxf(0.0, army.morale - s.tuning.defeat_morale_loss)

		if captured:
			city.owner_side = &"player"
			city.troops = 0
			city.morale = s.tuning.morale_start
			city.victory_cooldown = 2
			army.victory_cooldown = 2

		army.hold_left = s.tuning.march_hold_turns
		events.append({"t": &"assault", "army": army.id, "city": city.id,
				"att_losses": att_losses, "def_losses": def_losses, "captured": captured})

		if army.troops <= 0:
			s.set_general_busy(army.general_id, false)
			s.armies.erase(army.id)
			events.append({"t": &"army_disbanded", "id": army.id})


static func _production(s: CwState, _events: Array[Dictionary]) -> void:
	for value: Variant in s.cities.values():
		var c: CwCity = value as CwCity
		c.food += c.production_per_day * 3


static func _consumption(s: CwState, events: Array[Dictionary]) -> void:
	for value: Variant in s.cities.values():
		var c: CwCity = value as CwCity
		c.starving = _consume(c, events, &"city", c.id)
	for value: Variant in s.camps.values():
		var camp: CwCamp = value as CwCamp
		camp.starving = _consume(camp, events, &"camp", camp.id)
	for value: Variant in s.armies.values():
		var a: CwArmy = value as CwArmy
		a.starving = _consume(a, events, &"army", a.id)


static func _consume(entity: RefCounted, events: Array[Dictionary],
		kind: StringName, id: Variant) -> bool:
	var need: int = int(entity.call(&"food_per_turn"))
	var stock: int = int(entity.get(&"food"))
	if stock >= need:
		entity.set(&"food", stock - need)
		return false

	entity.set(&"food", 0)
	events.append({"t": &"starving", "kind": kind, "id": id})
	return true


static func _morale(s: CwState, events: Array[Dictionary]) -> void:
	for value: Variant in s.cities.values():
		var c: CwCity = value as CwCity
		if not c.starving:
			continue
		c.morale = maxf(c.morale - s.tuning.starve_morale_loss, 0.0)
		if c.morale <= 0.0:
			var to: StringName = &"enemy" if c.owner_side == &"player" else &"player"
			c.owner_side = to
			c.morale = s.tuning.morale_start
			c.starving = false
			events.append({"t": &"city_surrendered", "id": c.id, "to": to})

	for value: Variant in s.armies.values().duplicate():
		var a: CwArmy = value as CwArmy
		if not a.starving:
			continue
		a.morale = maxf(a.morale - s.tuning.starve_morale_loss, 0.0)
		if a.morale <= 0.0:
			s.set_general_busy(a.general_id, false)
			s.armies.erase(a.id)
			events.append({"t": &"army_disbanded", "id": a.id})

	for value: Variant in s.camps.values().duplicate():
		var camp: CwCamp = value as CwCamp
		if not camp.starving:
			continue
		camp.morale = maxf(camp.morale - s.tuning.starve_morale_loss, 0.0)
		if camp.morale <= 0.0:
			s.set_general_busy(camp.general_id, false)
			s.camps.erase(camp.id)
			events.append({"t": &"camp_lost", "id": camp.id})


static func _endcheck(s: CwState, events: Array[Dictionary]) -> void:
	var has_enemy_city := false
	var has_player_city := false
	var total_player_troops := 0

	for value: Variant in s.cities.values():
		var city: CwCity = value as CwCity
		if city.owner_side == &"enemy":
			has_enemy_city = true
		elif city.owner_side == &"player":
			has_player_city = true
			total_player_troops += city.troops

	for value: Variant in s.armies.values():
		var army: CwArmy = value as CwArmy
		total_player_troops += army.troops

	for value: Variant in s.camps.values():
		var camp: CwCamp = value as CwCamp
		total_player_troops += camp.troops

	if not has_enemy_city:
		s.result = &"victory"
		events.append({"t": &"victory"})
		return

	if not has_player_city or total_player_troops <= 0 or s.turn >= s.tuning.turn_limit:
		s.result = &"defeat"
		events.append({"t": &"defeat"})
