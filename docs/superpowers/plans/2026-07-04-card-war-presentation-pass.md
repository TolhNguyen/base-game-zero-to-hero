# Card War Presentation Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the existing Card War tutorial screen from a debug-looking grid into a Vietnamese, polished tactical command surface while preserving the current 16x16 simulation.

**Architecture:** Keep `sim/` unchanged. Implement presentation in `game/modules/card_war/ui/`, Vietnamese display data in `game/content/cards/`, and UI coverage in `game/tests/card_war/test_battle_scene.gd`. `CwMapView` remains a custom `Node2D` renderer, but becomes responsible for polished terrain, entity tokens, selection, and route preview.

**Tech Stack:** Godot 4.7 GDScript, gdUnit4, existing Card War module/content definitions, existing `tools/check.sh` verification entrypoint.

---

## File Structure

- Modify `game/content/cards/card.march.tres`: Vietnamese display name.
- Modify `game/content/cards/card.gather_food.tres`: Vietnamese display name.
- Modify `game/content/cards/card.build_camp.tres`: Vietnamese display name.
- Modify `game/content/cards/card.transport.tres`: Vietnamese display name.
- Modify `game/content/cards/card.assault.tres`: Vietnamese display name.
- Modify `game/content/cards/card.feast.tres`: Vietnamese display name.
- Modify `game/modules/card_war/ui/battle.gd`: layout, Vietnamese copy, hand card controls, order preview, report text, route preview handoff to `CwMapView`.
- Modify `game/modules/card_war/ui/cw_map_view.gd`: soft war-table rendering, tokens, subdued grid, highlight, and route preview.
- Modify `game/tests/card_war/test_battle_scene.gd`: UI/content assertions for Vietnamese labels, hand bar, report text, and rejected-order messaging.

Do not modify:

- `game/core/`
- `tools/check*`
- `docs/governance/`
- `docs/contracts/`
- `game/modules/card_war/sim/` unless implementation reveals an unavoidable presentation bug; escalate before doing so.

---

### Task 1: Vietnamese Content and UI Copy

**Files:**
- Modify: `game/content/cards/card.march.tres`
- Modify: `game/content/cards/card.gather_food.tres`
- Modify: `game/content/cards/card.build_camp.tres`
- Modify: `game/content/cards/card.transport.tres`
- Modify: `game/content/cards/card.assault.tres`
- Modify: `game/content/cards/card.feast.tres`
- Modify: `game/modules/card_war/ui/battle.gd`
- Test: `game/tests/card_war/test_battle_scene.gd`

- [ ] **Step 1: Write failing tests for Vietnamese content labels**

Add this test to `game/tests/card_war/test_battle_scene.gd`:

```gdscript
func test_card_content_uses_vietnamese_display_names() -> void:
	var expected := {
		&"card.march": "Hành Quân",
		&"card.gather_food": "Thu Lương",
		&"card.build_camp": "Dựng Trại",
		&"card.transport": "Vận Lương",
		&"card.assault": "Công Thành",
		&"card.feast": "Mừng Công",
	}
	for card_id: StringName in expected:
		var path := "res://content/cards/%s.tres" % String(card_id).trim_prefix("card.")
		var card: CwCardDef = load(path)
		assert_str(card.display_name).is_equal(expected[card_id])
```

- [ ] **Step 2: Write failing tests for Vietnamese HUD and report copy**

Add this test to `game/tests/card_war/test_battle_scene.gd`:

```gdscript
func test_battle_scene_uses_vietnamese_hud_and_report_text() -> void:
	var scene: PackedScene = load("res://modules/card_war/ui/battle.tscn")
	var battle: Node2D = auto_free(scene.instantiate())
	add_child(battle)
	assert_bool(battle._hud_label.text.contains("Lượt")).is_true()
	assert_bool(battle._hud_label.text.contains("Quân lệnh")).is_true()
	assert_bool(battle._hud_label.text.contains("Lương")).is_true()
	assert_bool(battle._hud_label.text.contains("Sĩ khí")).is_true()
	assert_str(battle._event_text({"t": &"turn_ended", "turn": 2})).is_equal("Lượt 2 bắt đầu.")
	remove_child(battle)
```

- [ ] **Step 3: Run the targeted tests and verify they fail**

Run:

```bash
cd /d/base-game-zero-to-hero
bash game/addons/gdUnit4/runtest.sh -a res://tests/card_war/test_battle_scene.gd -c --ignoreHeadlessMode
```

Expected: FAIL because content display names and UI/report text are still English.

- [ ] **Step 4: Update card display names**

Change the `display_name` fields:

```text
game/content/cards/card.march.tres        display_name = "Hành Quân"
game/content/cards/card.gather_food.tres  display_name = "Thu Lương"
game/content/cards/card.build_camp.tres   display_name = "Dựng Trại"
game/content/cards/card.transport.tres    display_name = "Vận Lương"
game/content/cards/card.assault.tres      display_name = "Công Thành"
game/content/cards/card.feast.tres        display_name = "Mừng Công"
```

- [ ] **Step 5: Add Vietnamese copy helpers to `battle.gd`**

Near the existing dictionaries in `battle.gd`, add:

```gdscript
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
```

Update `_refresh()` HUD format:

```gdscript
_hud_label.text = "Lượt %d | Quân lệnh %d | Lương %d | Sĩ khí %.0f" % [
	state.turn,
	state.energy,
	state.total_player_food(),
	state.avg_player_morale(),
]
```

Update `_build_ui()` defaults:

```gdscript
_order_info.text = "Chọn một lá bài hoặc một đơn vị."
_confirm_btn.text = "Xác Nhận"
hand_title.text = "Bài Trên Tay"
_end_turn_btn.text = "Kết Thúc Lượt"
report_title.text = "Quân Tình"
close_btn.text = "Đóng"
```

- [ ] **Step 6: Update `_event_text()` to Vietnamese**

Replace the match returns with:

```gdscript
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
```

- [ ] **Step 7: Run targeted tests and commit**

Run:

```bash
cd /d/base-game-zero-to-hero
bash game/addons/gdUnit4/runtest.sh -a res://tests/card_war/test_battle_scene.gd -c --ignoreHeadlessMode
```

Expected: PASS for `test_card_content_uses_vietnamese_display_names` and `test_battle_scene_uses_vietnamese_hud_and_report_text`.

Commit:

```bash
git add game/content/cards game/modules/card_war/ui/battle.gd game/tests/card_war/test_battle_scene.gd
git commit -m "feat(card_war): localize tutorial command text" -m "Task: ad-hoc" -m "Evidence: gdUnit4 test_battle_scene PASS"
```

---

### Task 2: Command Surface Layout and Hand Cards

**Files:**
- Modify: `game/modules/card_war/ui/battle.gd`
- Test: `game/tests/card_war/test_battle_scene.gd`

- [ ] **Step 1: Write failing layout tests**

Add to `game/tests/card_war/test_battle_scene.gd`:

```gdscript
func test_presentation_layout_has_named_regions() -> void:
	var scene: PackedScene = load("res://modules/card_war/ui/battle.tscn")
	var battle: Node2D = auto_free(scene.instantiate())
	add_child(battle)
	assert_object(battle.get_node_or_null("UI/Root")).is_not_null()
	assert_object(battle.get_node_or_null("UI/Root/MainRow")).is_not_null()
	assert_object(battle.get_node_or_null("UI/Root/HandBar")).is_not_null()
	assert_object(battle.get_node_or_null("UI/Root/MainRow/ContextPanel")).is_not_null()
	remove_child(battle)


func test_hand_entries_render_as_cards_with_description_and_cost() -> void:
	var scene: PackedScene = load("res://modules/card_war/ui/battle.tscn")
	var battle: Node2D = auto_free(scene.instantiate())
	add_child(battle)
	var s: CwState = battle.state
	s.hand.clear()
	s.hand.append(&"card.march")
	battle._refresh()
	var first: Control = battle._hand_box.get_child(0) as Control
	assert_object(first).is_not_null()
	assert_bool(first.name.begins_with("Card_")).is_true()
	assert_bool(first.get_node("Button").text.contains("Hành Quân")).is_true()
	assert_bool(first.get_node("Description").text.contains("Điều một đạo quân")).is_true()
	remove_child(battle)
```

- [ ] **Step 2: Run targeted tests and verify they fail**

Run:

```bash
cd /d/base-game-zero-to-hero
bash game/addons/gdUnit4/runtest.sh -a res://tests/card_war/test_battle_scene.gd -c --ignoreHeadlessMode
```

Expected: FAIL because `UI/Root`, `HandBar`, and card child nodes do not exist.

- [ ] **Step 3: Rebuild `_build_ui()` layout with named regions**

In `battle.gd`, replace `_build_ui()` with a version that creates:

```gdscript
var root := VBoxContainer.new()
root.name = "Root"
root.set_anchors_preset(Control.PRESET_FULL_RECT)
layer.add_child(root)

_hud_label = Label.new()
_hud_label.name = "Hud"
root.add_child(_hud_label)

var main_row := HBoxContainer.new()
main_row.name = "MainRow"
main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
root.add_child(main_row)

var map_spacer := Control.new()
map_spacer.name = "MapSpace"
map_spacer.custom_minimum_size = Vector2(660, 650)
map_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
map_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
main_row.add_child(map_spacer)

var panel := PanelContainer.new()
panel.name = "ContextPanel"
panel.custom_minimum_size = Vector2(430, 0)
panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
main_row.add_child(panel)

var context := VBoxContainer.new()
context.name = "ContextBox"
panel.add_child(context)
```

Move existing `_status_label`, `_order_info`, `_troops_spin`, `_food_spin`, `_confirm_btn`, `_end_turn_btn`, `_report_panel`, and `_result_label` into `context`.

Add bottom hand bar:

```gdscript
var hand_panel := PanelContainer.new()
hand_panel.name = "HandBar"
hand_panel.custom_minimum_size = Vector2(0, 132)
root.add_child(hand_panel)

var hand_scroll := ScrollContainer.new()
hand_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
hand_panel.add_child(hand_scroll)

_hand_box = HBoxContainer.new()
_hand_box.name = "HandCards"
_hand_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
hand_scroll.add_child(_hand_box)
```

Keep `MapView` as `Node2D` in the scene at the left. Do not parent it into `Control`; this task only names and restructures the UI `CanvasLayer` controls.

- [ ] **Step 4: Replace `_add_hand_entry()` with card-shaped controls**

Use this structure:

```gdscript
func _add_hand_entry(card: StringName) -> void:
	var cost := state.card_cost(card)
	var card_panel := PanelContainer.new()
	card_panel.name = "Card_%s" % String(card).replace(".", "_")
	card_panel.custom_minimum_size = Vector2(150, 104)
	card_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hand_box.add_child(card_panel)

	var box := VBoxContainer.new()
	card_panel.add_child(box)

	var b := Button.new()
	b.name = "Button"
	b.text = "%s\n%d quân lệnh" % [_card_names.get(card, String(card)), cost]
	b.disabled = state.energy < cost or state.result != &""
	b.pressed.connect(_begin_card.bind(card))
	box.add_child(b)

	var desc := Label.new()
	desc.name = "Description"
	desc.text = _card_descriptions.get(card, "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(0, 34)
	box.add_child(desc)
```

- [ ] **Step 5: Run targeted tests and commit**

Run:

```bash
cd /d/base-game-zero-to-hero
bash game/addons/gdUnit4/runtest.sh -a res://tests/card_war/test_battle_scene.gd -c --ignoreHeadlessMode
```

Expected: PASS for new layout and hand card tests.

Commit:

```bash
git add game/modules/card_war/ui/battle.gd game/tests/card_war/test_battle_scene.gd
git commit -m "feat(card_war): add command surface layout" -m "Task: ad-hoc" -m "Evidence: gdUnit4 test_battle_scene PASS"
```

---

### Task 3: Soft War-Table Map Renderer

**Files:**
- Modify: `game/modules/card_war/ui/cw_map_view.gd`
- Modify: `game/modules/card_war/ui/battle.gd`
- Test: `game/tests/card_war/test_battle_scene.gd`

- [ ] **Step 1: Write failing tests for route preview API**

Add to `game/tests/card_war/test_battle_scene.gd`:

```gdscript
func test_march_preview_sets_map_route_preview() -> void:
	var scene: PackedScene = load("res://modules/card_war/ui/battle.tscn")
	var battle: Node2D = auto_free(scene.instantiate())
	add_child(battle)
	var s: CwState = battle.state
	s.hand.clear()
	s.hand.append(&"card.march")
	battle._refresh()
	battle._begin_card(&"card.march")
	battle._troops_spin.value = 2000
	battle._on_tile_clicked(Vector2i(8, 3))
	assert_bool(battle.map_view.preview_path.size() > 0).is_true()
	assert_that(battle.map_view.preview_path[-1]).is_equal(Vector2i(8, 3))
	remove_child(battle)
```

- [ ] **Step 2: Run targeted tests and verify they fail**

Run:

```bash
cd /d/base-game-zero-to-hero
bash game/addons/gdUnit4/runtest.sh -a res://tests/card_war/test_battle_scene.gd -c --ignoreHeadlessMode
```

Expected: FAIL because `preview_path` does not exist.

- [ ] **Step 3: Add preview path state to `CwMapView`**

Add to `cw_map_view.gd`:

```gdscript
var preview_path: Array[Vector2i] = []


func set_preview_path(path: Array[Vector2i]) -> void:
	preview_path = path.duplicate()
	queue_redraw()


func clear_preview_path() -> void:
	preview_path.clear()
	queue_redraw()
```

Update `battle.gd`:

```gdscript
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
```

Update `_cancel_order()`:

```gdscript
map_view.clear_preview_path()
```

- [ ] **Step 4: Replace flat terrain drawing with soft board rendering**

In `cw_map_view.gd`, keep `TILE := 40` and `_tile_rect()`. Update `_draw()` order:

```gdscript
_draw_board_backdrop()
_draw_terrain()
_draw_preview_path()
_draw_cities()
_draw_camps()
_draw_convoys()
_draw_armies()
_draw_highlight()
```

Add helpers:

```gdscript
func _draw_board_backdrop() -> void:
	var board := Rect2(Vector2.ZERO, Vector2(state.map.size.x * TILE, state.map.size.y * TILE))
	draw_rect(board.grow(18.0), Color(0.10, 0.08, 0.07), true)
	draw_rect(board.grow(10.0), Color(0.28, 0.20, 0.12), false, 4.0)


func _draw_terrain() -> void:
	for y: int in range(state.map.size.y):
		for x: int in range(state.map.size.x):
			var p := Vector2i(x, y)
			var rect := _tile_rect(p).grow(-1.0)
			draw_rect(rect, _terrain_color(state.map.letter_at(p)), true)
			draw_rect(rect, Color(0.08, 0.06, 0.04, 0.22), false, 1.0)


func _draw_preview_path() -> void:
	if preview_path.size() < 2:
		return
	for i: int in range(preview_path.size() - 1):
		draw_line(_tile_center(preview_path[i]), _tile_center(preview_path[i + 1]),
				Color(1.0, 0.72, 0.28, 0.92), 4.0)
	for tile: Vector2i in preview_path:
		draw_circle(_tile_center(tile), 4.0, Color(1.0, 0.86, 0.42, 0.95))


func _draw_highlight() -> void:
	if state.map.in_bounds(highlight):
		draw_rect(_tile_rect(highlight).grow(-3.0), Color(1.0, 0.84, 0.42), false, 3.0)
```

Use darker war-table terrain colors:

```gdscript
func _terrain_color(letter: String) -> Color:
	match letter:
		"P":
			return Color(0.46, 0.42, 0.28)
		"F":
			return Color(0.16, 0.34, 0.20)
		"R":
			return Color(0.18, 0.34, 0.42)
		"M":
			return Color(0.30, 0.29, 0.28)
		"H":
			return Color(0.20, 0.31, 0.48)
		"E":
			return Color(0.45, 0.20, 0.18)
		_:
			return Color(0.12, 0.12, 0.12)
```

- [ ] **Step 5: Redraw entity tokens with distinct silhouettes**

Update `_draw_cities()`, `_draw_camps()`, `_draw_convoys()`, and `_draw_armies()` to use labels and tokens:

```gdscript
func _draw_cities() -> void:
	var font: Font = ThemeDB.fallback_font
	for value: Variant in state.cities.values():
		var city: CwCity = value as CwCity
		var fill := Color(0.14, 0.28, 0.50) if city.owner_side == &"player" else Color(0.55, 0.17, 0.15)
		var outline := Color(0.95, 0.76, 0.36) if city.owner_side == &"player" else Color(1.0, 0.48, 0.36)
		var bounds := _city_bounds(city)
		draw_rect(bounds.grow(-3.0), fill, true)
		draw_rect(bounds.grow(-3.0), outline, false, 3.0)
		if font != null:
			var label := "Thành Nhà" if city.owner_side == &"player" else "Thành Địch"
			draw_string(font, bounds.position + Vector2(4, 22), label,
					HORIZONTAL_ALIGNMENT_CENTER, bounds.size.x - 8, 13, Color(1.0, 0.90, 0.66))


func _city_bounds(city: CwCity) -> Rect2:
	var min_x := city.tiles[0].x
	var min_y := city.tiles[0].y
	var max_x := min_x
	var max_y := min_y
	for tile: Vector2i in city.tiles:
		min_x = mini(min_x, tile.x)
		min_y = mini(min_y, tile.y)
		max_x = maxi(max_x, tile.x)
		max_y = maxi(max_y, tile.y)
	return Rect2(Vector2(min_x * TILE, min_y * TILE),
			Vector2((max_x - min_x + 1) * TILE, (max_y - min_y + 1) * TILE))
```

Keep labels short enough to fit at 40px tiles. If text crowding appears in manual verification, shorten to `Nhà` and `Địch`.

- [ ] **Step 6: Run targeted tests and commit**

Run:

```bash
cd /d/base-game-zero-to-hero
bash game/addons/gdUnit4/runtest.sh -a res://tests/card_war/test_battle_scene.gd -c --ignoreHeadlessMode
```

Expected: PASS for route preview API and existing scene tests.

Commit:

```bash
git add game/modules/card_war/ui/cw_map_view.gd game/modules/card_war/ui/battle.gd game/tests/card_war/test_battle_scene.gd
git commit -m "feat(card_war): render tactical war table map" -m "Task: ad-hoc" -m "Evidence: gdUnit4 test_battle_scene PASS"
```

---

### Task 4: Rejection Reasons and Report Polish

**Files:**
- Modify: `game/modules/card_war/ui/battle.gd`
- Test: `game/tests/card_war/test_battle_scene.gd`

- [ ] **Step 1: Write failing tests for Vietnamese rejection copy**

Update `test_rejected_order_reports_reason_and_keeps_state()`:

```gdscript
func test_rejected_order_reports_reason_and_keeps_state() -> void:
	var scene: PackedScene = load("res://modules/card_war/ui/battle.tscn")
	var battle: Node2D = auto_free(scene.instantiate())
	add_child(battle)
	var s: CwState = battle.state
	s.hand.clear()
	s.hand.append(&"card.march")
	battle._begin_card(&"card.march")
	battle._troops_spin.value = 9000
	battle._on_tile_clicked(Vector2i(8, 3))
	battle._confirm_order()
	assert_int(s.pending.size()).is_equal(0)
	assert_int(s.energy).is_equal(3)
	assert_bool(battle._status_label.text.contains("Không thể thực hiện lệnh")).is_true()
	assert_bool(battle._status_label.text.contains("quân")).is_true()
	remove_child(battle)
```

- [ ] **Step 2: Run targeted tests and verify they fail**

Run:

```bash
cd /d/base-game-zero-to-hero
bash game/addons/gdUnit4/runtest.sh -a res://tests/card_war/test_battle_scene.gd -c --ignoreHeadlessMode
```

Expected: FAIL because rejection copy still uses the old generic English `err`.

- [ ] **Step 3: Add local rejection helper**

Add to `battle.gd`:

```gdscript
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
```

Update `_confirm_order()` rejection branch:

```gdscript
if err != OK:
	_status_label.text = _order_rejection_text(o)
	return
```

Update success branch:

```gdscript
_status_label.text = "Đã ghi lệnh cho lượt này."
```

- [ ] **Step 4: Make result/report labels visually distinct through text**

In `_end_turn()`, update result label:

```gdscript
_result_label.text = "CHIẾN THẮNG" if state.result == &"victory" else "THẤT BẠI"
```

No color assertion is required in tests. Visual color polish can be implemented directly in UI code if local style overrides are simple.

- [ ] **Step 5: Run targeted tests and commit**

Run:

```bash
cd /d/base-game-zero-to-hero
bash game/addons/gdUnit4/runtest.sh -a res://tests/card_war/test_battle_scene.gd -c --ignoreHeadlessMode
```

Expected: PASS.

Commit:

```bash
git add game/modules/card_war/ui/battle.gd game/tests/card_war/test_battle_scene.gd
git commit -m "feat(card_war): polish Vietnamese order feedback" -m "Task: ad-hoc" -m "Evidence: gdUnit4 test_battle_scene PASS"
```

---

### Task 5: Full Verification and Manual Visual Evidence

**Files:**
- Modify only if verification reveals an issue:
  - `game/modules/card_war/ui/battle.gd`
  - `game/modules/card_war/ui/cw_map_view.gd`
  - `game/tests/card_war/test_battle_scene.gd`

- [ ] **Step 1: Run full project check**

Run from Git Bash:

```bash
cd /d/base-game-zero-to-hero
bash tools/check.sh
```

Expected:

```text
CHECK: PASS
Overall Summary: 168+ test cases | 0 errors | 0 failures
check: boot smoke OK
```

The exact test count may increase after adding UI tests.

- [ ] **Step 2: Capture manual visual evidence**

Run the scene in Godot from the project root:

```bash
tools/godot/Godot_v4.7-stable_win64.exe --path game
```

Open or run `res://modules/card_war/ui/battle.tscn`. Verify by sight:

- HUD says `Lượt`, `Quân lệnh`, `Lương`, `Sĩ khí`.
- Hand cards are horizontal at the bottom.
- At least one hand card shows Vietnamese name, cost, and description.
- Player city and enemy city are visually different.
- Army/general token is visually different from city/camp/convoy tokens.
- Map reads as a tactical war table rather than flat debug colors.
- Selecting `Hành Quân` shows a preview route and Vietnamese preview text.
- No obvious text overflow at the default 1280x720 window.

- [ ] **Step 3: Fix any visual issue found in manual verification**

If a specific issue appears, make the smallest correction. Examples:

```gdscript
# If city labels do not fit:
var label := "Nhà" if city.owner_side == &"player" else "Địch"
```

```gdscript
# If hand cards are too narrow:
card_panel.custom_minimum_size = Vector2(170, 104)
```

After any fix, rerun:

```bash
cd /d/base-game-zero-to-hero
bash game/addons/gdUnit4/runtest.sh -a res://tests/card_war/test_battle_scene.gd -c --ignoreHeadlessMode
```

Expected: PASS.

- [ ] **Step 4: Final commit**

If Step 3 changed files:

```bash
git add game/modules/card_war/ui game/tests/card_war
git commit -m "fix(card_war): refine presentation pass visuals" -m "Task: ad-hoc" -m "Evidence: tools/check.sh PASS; manual battle scene review"
```

If Step 3 changed nothing, do not create an empty commit. Use the final status report to cite the full `tools/check.sh` evidence.

---

## Self-Review

Spec coverage:

- Vietnamese game-facing language: Task 1 and Task 4.
- B+C sa ban/dem trai mood: Task 2 and Task 3.
- Visible hand cards: Task 2.
- Distinct army/general/city/camp/convoy tokens: Task 3.
- Rejection/report polish: Task 4.
- No sim/core changes: file boundaries and all task scopes.
- Verification: Task 5.

Placeholder scan:

- No placeholder markers or deferred-work wording remain in the task steps.
- Each test step includes exact test code and expected failure/pass condition.
- Each implementation task names exact files and concrete code snippets.

Type consistency:

- `preview_path`, `set_preview_path()`, and `clear_preview_path()` are introduced in Task 3 before `battle.gd` uses them.
- Existing `battle.gd` members `_hud_label`, `_status_label`, `_order_info`, `_hand_box`, `_report_panel`, `_report_text`, `_result_label`, `_troops_spin`, `_food_spin`, `_confirm_btn`, and `_end_turn_btn` are reused rather than renamed.
- Existing `CwState` APIs remain unchanged.
