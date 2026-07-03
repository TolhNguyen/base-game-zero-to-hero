class_name CwBuilder
extends RefCounted
## Builds a ready CwState from content Definitions. The only sim-side code
## that touches Resources; it still never touches Registry or autoloads.

static func build(scenario: CwScenarioDef, map_def: CwMapDef,
		terrains: Array[CwTerrainDef], cards: Array[CwCardDef],
		generals: Array[CwGeneralDef], seed_value: int) -> CwState:
	var letter_cost := {}
	for t: CwTerrainDef in terrains:
		letter_cost[t.letter] = t.move_cost
	var grid := CwMapGrid.from_rows(map_def.rows, letter_cost)
	var s := CwState.new()
	s.setup(grid, CwTuning.from_def(scenario), seed_value)
	for c: CwCardDef in cards:
		s.register_card(c.id, c.order_type, c.energy_cost)
	for g: CwGeneralDef in generals:
		s.register_general(g.id, g.combat_factor, g.loss_reduction)
	s.add_city(&"city.home", &"player", grid.tiles_with_letter("H"),
			scenario.home_troops, scenario.home_food,
			scenario.home_production_per_day, 1.0)
	s.add_city(&"city.enemy", &"enemy", grid.tiles_with_letter("E"),
			scenario.enemy_troops, scenario.enemy_food,
			scenario.enemy_production_per_day, scenario.enemy_wall_factor)
	var deck: Array[StringName] = []
	for card_id: Variant in scenario.deck:
		for i: int in int(scenario.deck[card_id]):
			deck.append(StringName(card_id))
	s.set_deck(deck)
	return s
