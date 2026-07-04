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
var _hand_box: HBoxContainer
var _report_panel: PanelContainer
var _report_text: RichTextLabel
var _result_label: Label
var _card_names: Dictionary = {}
var _card_descriptions: Dictionary = {
	&"card.march": "Điều một đạo quân tới vị trí chọn.",
	&"card.gather_food": "Tăng lương dự trữ tại thành.",
	&"card.build_camp": "Dựng doanh trại tại vị trí đạo quân.",
	&"card.transport": "Chuyển lương tới trại hoặc đạo quân.",
	&"card.assault": "Công thành bằng đạo quân đang áp sát.",
	&"card.feast": "Tăng sĩ khí sau chiến thắng.",
}
var _order_type_names: Dictionary = {
	&"march": "Hành Quân",
	&"gather_food": "Thu Lương",
	&"build_camp": "Dựng Trại",
	&"transport": "Vận Lương",
	&"assault": "Công Thành",
	&"feast": "Mừng Công",
}
var _card: StringName = &""
var _stage: StringName = &""
var _params: Dictionary = {}


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

	var root := VBoxContainer.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root)

	_hud_label = Label.new()
	_hud_label.name = "Hud"
	root.add_child(_hud_label)

	var main_row := HBoxContainer.new()
	main_row.name = "MainRow"
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(main_row)

	var map_spacer := Control.new()
	map_spacer.name = "MapSpace"
	map_spacer.custom_minimum_size = Vector2(590, 590)
	map_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_row.add_child(map_spacer)

	var panel := PanelContainer.new()
	panel.name = "ContextPanel"
	panel.custom_minimum_size = Vector2(430, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_child(panel)

	var context := VBoxContainer.new()
	context.name = "ContextBox"
	panel.add_child(context)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(0, 74)
	context.add_child(_status_label)

	_order_info = Label.new()
	_order_info.text = "Chọn một lá bài hoặc một đơn vị."
	_order_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	context.add_child(_order_info)

	_troops_spin = SpinBox.new()
	_troops_spin.min_value = 100
	_troops_spin.max_value = 10000
	_troops_spin.step = 100
	_troops_spin.value = 2000
	_troops_spin.prefix = "Troops "
	_troops_spin.visible = false
	context.add_child(_troops_spin)

	_food_spin = SpinBox.new()
	_food_spin.min_value = 30
	_food_spin.max_value = 5000
	_food_spin.step = 30
	_food_spin.value = 300
	_food_spin.prefix = "Food "
	_food_spin.visible = false
	context.add_child(_food_spin)

	_confirm_btn = Button.new()
	_confirm_btn.text = "Xác Nhận"
	_confirm_btn.visible = false
	_confirm_btn.pressed.connect(_confirm_order)
	context.add_child(_confirm_btn)

	_end_turn_btn = Button.new()
	_end_turn_btn.text = "Kết Thúc Lượt"
	_end_turn_btn.pressed.connect(_end_turn)
	context.add_child(_end_turn_btn)

	_report_panel = PanelContainer.new()
	_report_panel.visible = false
	_report_panel.custom_minimum_size = Vector2(0, 190)
	context.add_child(_report_panel)

	var report_box := VBoxContainer.new()
	_report_panel.add_child(report_box)

	var report_header := HBoxContainer.new()
	report_box.add_child(report_header)

	var report_title := Label.new()
	report_title.text = "Quân Tình"
	report_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report_header.add_child(report_title)

	var close_btn := Button.new()
	close_btn.text = "Đóng"
	close_btn.pressed.connect(func() -> void: _report_panel.visible = false)
	report_header.add_child(close_btn)

	_report_text = RichTextLabel.new()
	_report_text.custom_minimum_size = Vector2(0, 140)
	_report_text.fit_content = true
	report_box.add_child(_report_text)

	_result_label = Label.new()
	_result_label.visible = false
	context.add_child(_result_label)

	var hand_panel := PanelContainer.new()
	hand_panel.name = "HandBar"
	hand_panel.custom_minimum_size = Vector2(0, 120)
	root.add_child(hand_panel)

	var hand_scroll := ScrollContainer.new()
	hand_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_panel.add_child(hand_scroll)

	_hand_box = HBoxContainer.new()
	_hand_box.name = "HandCards"
	_hand_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_scroll.add_child(_hand_box)


func _refresh() -> void:
	if state == null:
		return

	_hud_label.text = "Lượt %d | Quân lệnh %d | Lương %d | Sĩ khí %.0f" % [
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


func _add_hand_entry(card: StringName) -> void:
	var cost := state.card_cost(card)
	var card_panel := VBoxContainer.new()
	card_panel.name = "Card_%s" % String(card).replace(".", "_")
	card_panel.custom_minimum_size = Vector2(150, 96)
	card_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hand_box.add_child(card_panel)

	var b := Button.new()
	b.name = "Button"
	b.text = "%s\n%d quân lệnh" % [_card_names.get(card, String(card)), cost]
	b.disabled = state.energy < cost or state.result != &""
	b.custom_minimum_size = Vector2(0, 48)
	b.pressed.connect(_begin_card.bind(card))
	card_panel.add_child(b)

	var desc := Label.new()
	desc.name = "Description"
	desc.text = _card_descriptions.get(card, "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc.max_lines_visible = 1
	desc.clip_text = true
	desc.custom_minimum_size = Vector2(0, 24)
	card_panel.add_child(desc)


func _begin_card(card: StringName) -> void:
	_cancel_order()
	_card = card
	match state.card_type(card):
		&"march":
			var free: Array[StringName] = state.free_generals()
			if free.is_empty():
				_status_label.text = "No free general to lead the march."
				_card = &""
				return
			_params["general_id"] = free[0]
			_params["from_city"] = _first_player_city()
			_stage = &"pick_dest"
			_troops_spin.visible = true
			_status_label.text = "March: set troops, then click a destination tile."
		&"gather_food":
			_params["city"] = _first_player_city()
			_order_info.text = "Gather food at %s." % _params["city"]
			_confirm_btn.visible = true
		&"build_camp":
			_stage = &"pick_army"
			_status_label.text = "Build camp: click one of your armies."
		&"transport":
			_params["from_city"] = _first_player_city()
			_stage = &"pick_target"
			_food_spin.visible = true
			_status_label.text = "Transport: set amount, then click a camp or army."
		&"assault":
			_stage = &"pick_army"
			_status_label.text = "Assault: click your army, then the enemy city."
		&"feast":
			_stage = &"pick_feast"
			_status_label.text = "Feast: click a victorious army or captured city."
		_:
			_status_label.text = "Unknown card type."
			_card = &""


func _on_tile_clicked(tile: Vector2i) -> void:
	if _card == &"":
		_show_tile_info(tile)
		return
	match _stage:
		&"pick_dest":
			_params["to"] = tile
			_update_march_preview()
		&"pick_army":
			var a: CwArmy = state.army_at(tile)
			if a == null:
				_status_label.text = "No army on that tile."
				return
			_params["army_id"] = a.id
			if state.card_type(_card) == &"assault":
				_stage = &"pick_enemy_city"
				_status_label.text = "Now click the enemy city."
			else:
				_order_info.text = "Build camp at %s." % str(a.pos)
				_confirm_btn.visible = true
		&"pick_enemy_city":
			var c: CwCity = state.city_at(tile)
			if c == null or c.owner_side != &"enemy":
				_status_label.text = "Click an enemy city tile."
				return
			_params["city"] = c.id
			_order_info.text = "Assault %s." % c.id
			_confirm_btn.visible = true
		&"pick_target":
			var camp: CwCamp = state.camp_at(tile)
			var army: CwArmy = state.army_at(tile)
			if camp != null:
				_params["target_kind"] = &"camp"
				_params["target_id"] = camp.id
			elif army != null:
				_params["target_kind"] = &"army"
				_params["target_id"] = army.id
			else:
				_status_label.text = "Click a camp or an army."
				return
			_order_info.text = "Send %d food." % int(_food_spin.value)
			_confirm_btn.visible = true
		&"pick_feast":
			var fa: CwArmy = state.army_at(tile)
			var fc: CwCity = state.city_at(tile)
			if fa != null:
				_params["target_kind"] = &"army"
				_params["target_id"] = fa.id
			elif fc != null and fc.owner_side == &"player":
				_params["target_kind"] = &"city"
				_params["target_id"] = fc.id
			else:
				_status_label.text = "Click an army or one of your cities."
				return
			_order_info.text = "Hold a victory feast."
			_confirm_btn.visible = true


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
	_cancel_order()

	var events: Array[Dictionary] = CwResolver.resolve(state)
	var lines := PackedStringArray()
	for event: Dictionary in events:
		lines.append(_event_text(event))
	_report_text.text = "\n".join(lines)
	_report_panel.visible = true
	_refresh()

	if state.result != &"":
		_result_label.visible = true
		_result_label.text = "CHIẾN THẮNG" if state.result == &"victory" else "THẤT BẠI"
		_end_turn_btn.disabled = true

		var bus: Node = get_node_or_null("/root/EventBus")
		if bus != null:
			var topic := &"card_war.victory" if state.result == &"victory" else &"card_war.defeat"
			bus.call("publish", topic, {"turn": state.turn})


func _event_text(e: Dictionary) -> String:
	var t := StringName(e.get("t", &""))
	match t:
		&"order_started":
			var order_type := StringName(e.get("type", &""))
			return "Lệnh bắt đầu: %s." % _order_type_names.get(order_type, String(order_type))
		&"army_moved":
			return "Đạo quân %d tiến tới %s." % [int(e.get("id", 0)), e.get("pos", Vector2i.ZERO)]
		&"army_arrived":
			return "Đạo quân %d đã tới %s." % [int(e.get("id", 0)), e.get("pos", Vector2i.ZERO)]
		&"army_returning":
			return "Đạo quân %d đang rút về thành." % int(e.get("id", 0))
		&"army_returned":
			return "Đạo quân %d đã trở về thành." % int(e.get("id", 0))
		&"army_disbanded":
			return "Đạo quân %d tan rã." % int(e.get("id", 0))
		&"army_lost":
			return "Đạo quân %d bị tiêu diệt." % int(e.get("id", 0))
		&"camp_built":
			return "Doanh trại %d được dựng tại %s." % [int(e.get("id", 0)), e.get("pos", Vector2i.ZERO)]
		&"camp_lost":
			return "Doanh trại %d bị phá." % int(e.get("id", 0))
		&"convoy_arrived":
			return "Đoàn vận lương %d đã tới nơi." % int(e.get("id", 0))
		&"food_gathered":
			return "%s thu được %d lương." % [e.get("city", &""), int(e.get("amount", 0))]
		&"feast_held":
			return "Mở tiệc mừng công cho %s %s." % [e.get("kind", &""), e.get("id", "")]
		&"assault":
			var captured: String = " Thành thất thủ." if bool(e.get("captured", false)) else ""
			return "Đạo quân %d công %s: ta mất %d, địch mất %d.%s" % [
				int(e.get("army", 0)),
				e.get("city", &""),
				int(e.get("att_losses", 0)),
				int(e.get("def_losses", 0)),
				captured,
			]
		&"starving":
			return "%s %s đang thiếu lương." % [e.get("kind", &""), e.get("id", "")]
		&"city_surrendered":
			return "%s đầu hàng %s." % [e.get("id", &""), e.get("to", &"")]
		&"victory":
			return "Chiến thắng."
		&"defeat":
			return "Thất bại."
		&"turn_ended":
			return "Lượt %d bắt đầu." % int(e.get("turn", 0))
		_:
			return String(t)


func _update_march_preview() -> void:
	var city: CwCity = state.cities[_params["from_city"]]
	var path: Array[Vector2i] = state.map.find_path(state.spawn_tile(city), _params["to"])
	if path.is_empty():
		map_view.clear_preview_path()
		_order_info.text = "Không thể hành quân tới vị trí đó."
		_confirm_btn.visible = false
		return
	map_view.set_preview_path(path)
	var troops := int(_troops_spin.value)
	var turns := state.map.turns_for_path(path, state.tuning.move_points_per_turn)
	var food := state.march_food_needed(troops, path)
	_order_info.text = "Hành Quân %d quân: tới nơi sau %d lượt, cần %d lương." % [troops, turns, food]
	_confirm_btn.visible = true


func _order_rejection_text(order: CwOrder) -> String:
	match order.type:
		&"march":
			return "Không thể thực hiện lệnh Hành Quân: kiểm tra quân số, lương, tướng rảnh và đường đi."
		&"transport":
			return "Không thể Vận Lương: kiểm tra lượng lương và mục tiêu nhận lương."
		&"assault":
			return "Không thể Công Thành: đạo quân phải giữ vị trí cạnh thành địch."
		&"build_camp":
			return "Không thể Dựng Trại: chọn đạo quân đang giữ vị trí."
		&"feast":
			return "Không thể Mừng Công: mục tiêu cần vừa có chiến công và đủ lương."
		_:
			return "Không thể thực hiện lệnh: điều kiện chưa hợp lệ."


func _confirm_order() -> void:
	if _card == &"":
		return
	var o := CwOrder.new()
	o.card_id = _card
	o.type = state.card_type(_card)
	if o.type == &"march":
		_params["troops"] = int(_troops_spin.value)
	if o.type == &"transport":
		_params["food"] = int(_food_spin.value)
	o.params = _params.duplicate()
	var err: Error = state.play_card(o)
	if err != OK:
		_status_label.text = _order_rejection_text(o)
		return
	_status_label.text = "Đã ghi lệnh cho lượt này."
	_cancel_order()
	_refresh()


func _cancel_order() -> void:
	_card = &""
	_stage = &""
	_params = {}
	_order_info.text = ""
	map_view.clear_preview_path()
	_troops_spin.visible = false
	_food_spin.visible = false
	_confirm_btn.visible = false


func _first_player_city() -> StringName:
	for value: Variant in state.cities.values():
		var c: CwCity = value as CwCity
		if c.owner_side == &"player":
			return c.id
	return &""
