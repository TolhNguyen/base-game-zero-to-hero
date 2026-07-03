extends Node2D

const SCENARIO_ID := &"scenario.tutorial_01"

@onready var map_view: CwMapView = $MapView

var state: CwState
var _hud_label: Label
var _status_label: Label
var _order_info: Label
var _troops_spin: SpinBox
var _food_spin: SpinBox
var _confirm_btn: Button
var _end_turn_btn: Button
var _hand_box: VBoxContainer
var _report_panel: PanelContainer
var _report_text: RichTextLabel
var _result_label: Label
var _card_names: Dictionary = {}


func _ready() -> void:
	var registry: Node = get_node_or_null("/root/Registry")
	if registry == null:
		push_error("Card War battle requires Registry autoload.")
		return

	if not bool(registry.call("has_def", SCENARIO_ID)):
		var err: int = int(registry.call("scan", "res://content"))
		if err != OK:
			push_error("Card War battle content scan failed: %s" % err)
			return

	state = _build_state(registry)
	if state == null:
		push_error("Card War battle state could not be built.")
		return

	map_view.state = state
	map_view.tile_clicked.connect(_on_tile_clicked)
	_build_ui()
	_refresh()


func _build_state(registry: Node) -> CwState:
	var scenario: CwScenarioDef = registry.call("get_def", SCENARIO_ID) as CwScenarioDef
	if scenario == null:
		return null

	var map_def: CwMapDef = registry.call("get_def", scenario.map_id) as CwMapDef
	if map_def == null:
		return null

	var terrains: Array[CwTerrainDef] = []
	var terrain_letters := {}
	for id: StringName in registry.call("ids_with_prefix", "terrain."):
		var terrain: CwTerrainDef = registry.call("get_def", id) as CwTerrainDef
		if terrain == null:
			push_error("Card War battle terrain '%s' is missing or has the wrong type." % id)
			return null
		terrains.append(terrain)
		terrain_letters[terrain.letter] = true
	for row: String in map_def.rows:
		for i: int in row.length():
			var letter := row.substr(i, 1)
			if not terrain_letters.has(letter):
				push_error("Card War battle map uses terrain letter '%s' without a definition." % letter)
				return null

	var cards: Array[CwCardDef] = []
	var card_ids := {}
	_card_names.clear()
	for id: StringName in registry.call("ids_with_prefix", "card."):
		var card: CwCardDef = registry.call("get_def", id) as CwCardDef
		if card == null:
			push_error("Card War battle card '%s' is missing or has the wrong type." % id)
			return null
		cards.append(card)
		card_ids[card.id] = true
		_card_names[card.id] = card.display_name
	for card_id: Variant in scenario.deck.keys():
		var deck_card := StringName(card_id)
		if not card_ids.has(deck_card):
			push_error("Card War battle scenario deck references missing card '%s'." % deck_card)
			return null

	var generals: Array[CwGeneralDef] = []
	for id: String in scenario.general_ids:
		var general: CwGeneralDef = registry.call("get_def", StringName(id)) as CwGeneralDef
		if general == null:
			push_error("Card War battle general '%s' is missing or has the wrong type." % id)
			return null
		generals.append(general)

	return CwBuilder.build(scenario, map_def, terrains, cards, generals, randi())


func _build_ui() -> void:
	var layer: CanvasLayer = $UI
	var panel := PanelContainer.new()
	panel.position = Vector2(680, 16)
	panel.custom_minimum_size = Vector2(580, 688)
	layer.add_child(panel)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(root)

	_hud_label = Label.new()
	root.add_child(_hud_label)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(0, 90)
	root.add_child(_status_label)

	_order_info = Label.new()
	_order_info.text = "Select a tile."
	_order_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_order_info)

	_troops_spin = SpinBox.new()
	_troops_spin.min_value = 100
	_troops_spin.max_value = 10000
	_troops_spin.step = 100
	_troops_spin.value = 2000
	_troops_spin.prefix = "Troops "
	_troops_spin.visible = false
	root.add_child(_troops_spin)

	_food_spin = SpinBox.new()
	_food_spin.min_value = 30
	_food_spin.max_value = 5000
	_food_spin.step = 30
	_food_spin.value = 300
	_food_spin.prefix = "Food "
	_food_spin.visible = false
	root.add_child(_food_spin)

	_confirm_btn = Button.new()
	_confirm_btn.text = "Confirm"
	_confirm_btn.visible = false
	_confirm_btn.pressed.connect(_confirm_order)
	root.add_child(_confirm_btn)

	var hand_title := Label.new()
	hand_title.text = "Hand"
	root.add_child(hand_title)

	_hand_box = VBoxContainer.new()
	_hand_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_hand_box)

	_end_turn_btn = Button.new()
	_end_turn_btn.text = "End Turn"
	_end_turn_btn.pressed.connect(_end_turn)
	root.add_child(_end_turn_btn)

	_report_panel = PanelContainer.new()
	_report_panel.visible = false
	_report_panel.custom_minimum_size = Vector2(0, 190)
	root.add_child(_report_panel)

	var report_box := VBoxContainer.new()
	_report_panel.add_child(report_box)

	var report_header := HBoxContainer.new()
	report_box.add_child(report_header)

	var report_title := Label.new()
	report_title.text = "Report"
	report_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_header.add_child(report_title)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func() -> void: _report_panel.visible = false)
	report_header.add_child(close_btn)

	_report_text = RichTextLabel.new()
	_report_text.custom_minimum_size = Vector2(0, 140)
	_report_text.fit_content = true
	report_box.add_child(_report_text)

	_result_label = Label.new()
	_result_label.visible = false
	root.add_child(_result_label)


func _refresh() -> void:
	if state == null:
		return

	_hud_label.text = "Turn %d | Energy %d | Food %d | Morale %.0f" % [
		state.turn,
		state.energy,
		state.total_player_food(),
		state.avg_player_morale(),
	]

	for child: Node in _hand_box.get_children():
		_hand_box.remove_child(child)
		child.queue_free()
	for card: StringName in state.hand:
		_add_hand_entry(card)

	map_view.refresh()


func _add_hand_entry(card) -> void:
	var card_id := StringName(card)
	var label := Label.new()
	label.text = "%s - %d energy" % [
		String(_card_names.get(card_id, card_id)),
		state.card_cost(card_id),
	]
	_hand_box.add_child(label)


func _on_tile_clicked(tile: Vector2i) -> void:
	_show_tile_info(tile)


func _show_tile_info(tile) -> void:
	if state == null:
		return

	var p: Vector2i = tile
	var bits: Array[String] = []
	bits.append("Tile %s: %s" % [p, state.map.letter_at(p)])

	var city: CwCity = state.city_at(p)
	if city != null:
		bits.append("City %s (%s), troops %d, food %d, morale %.0f" % [
			city.id,
			city.owner_side,
			city.troops,
			city.food,
			city.morale,
		])

	var army: CwArmy = state.army_at(p)
	if army != null:
		bits.append("Army %d (%s), troops %d, food %d, morale %.0f" % [
			army.id,
			army.state,
			army.troops,
			army.food,
			army.morale,
		])

	var camp: CwCamp = state.camp_at(p)
	if camp != null:
		bits.append("Camp %d, troops %d, food %d, morale %.0f" % [
			camp.id,
			camp.troops,
			camp.food,
			camp.morale,
		])

	for value: Variant in state.convoys.values():
		var convoy: CwConvoy = value as CwConvoy
		if convoy.pos == p:
			bits.append("Convoy %d, food %d" % [convoy.id, convoy.food])

	_status_label.text = "\n".join(bits)


func _end_turn() -> void:
	if state == null or state.result != &"":
		return

	var events: Array[Dictionary] = CwResolver.resolve(state)
	var lines := PackedStringArray()
	for event: Dictionary in events:
		lines.append(_event_text(event))
	_report_text.text = "\n".join(lines)
	_report_panel.visible = true
	_refresh()

	if state.result != &"":
		_result_label.visible = true
		_result_label.text = "Victory" if state.result == &"victory" else "Defeat"
		_end_turn_btn.disabled = true

		var bus: Node = get_node_or_null("/root/EventBus")
		if bus != null:
			var topic := &"card_war.victory" if state.result == &"victory" else &"card_war.defeat"
			bus.call("publish", topic, {"turn": state.turn})


func _event_text(e: Dictionary) -> String:
	var t := StringName(e.get("t", &""))
	match t:
		&"order_started":
			return "Order started: %s" % e.get("type", &"")
		&"army_moved":
			return "Army %d moved to %s" % [int(e.get("id", 0)), e.get("pos", Vector2i.ZERO)]
		&"army_arrived":
			return "Army %d arrived at %s" % [int(e.get("id", 0)), e.get("pos", Vector2i.ZERO)]
		&"army_returning":
			return "Army %d is returning home" % int(e.get("id", 0))
		&"army_returned":
			return "Army %d returned home" % int(e.get("id", 0))
		&"army_disbanded":
			return "Army %d disbanded" % int(e.get("id", 0))
		&"army_lost":
			return "Army %d was lost" % int(e.get("id", 0))
		&"camp_built":
			return "Camp %d built at %s" % [int(e.get("id", 0)), e.get("pos", Vector2i.ZERO)]
		&"camp_lost":
			return "Camp %d was lost" % int(e.get("id", 0))
		&"convoy_arrived":
			return "Convoy %d arrived" % int(e.get("id", 0))
		&"food_gathered":
			return "%s gathered %d food" % [e.get("city", &""), int(e.get("amount", 0))]
		&"feast_held":
			return "Feast held for %s %s" % [e.get("kind", &""), e.get("id", "")]
		&"assault":
			var captured: String = " captured" if bool(e.get("captured", false)) else ""
			return "Army %d assaulted %s: attacker -%d, defender -%d%s" % [
				int(e.get("army", 0)),
				e.get("city", &""),
				int(e.get("att_losses", 0)),
				int(e.get("def_losses", 0)),
				captured,
			]
		&"starving":
			return "%s %s is starving" % [e.get("kind", &""), e.get("id", "")]
		&"city_surrendered":
			return "%s surrendered to %s" % [e.get("id", &""), e.get("to", &"")]
		&"victory":
			return "Victory"
		&"defeat":
			return "Defeat"
		&"turn_ended":
			return "Turn %d begins" % int(e.get("turn", 0))
		_:
			return String(t)


func _confirm_order() -> void:
	pass
