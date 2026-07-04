class_name CwMapView
extends Node2D

signal tile_clicked(tile: Vector2i)

const TILE := 40

var state: CwState
var highlight := Vector2i(-1, -1)
var preview_path: Array[Vector2i] = []


func refresh() -> void:
	queue_redraw()


func set_preview_path(path: Array[Vector2i]) -> void:
	preview_path = path.duplicate()
	queue_redraw()


func clear_preview_path() -> void:
	preview_path.clear()
	queue_redraw()


func _draw() -> void:
	if state == null or state.map == null:
		return

	_draw_board_backdrop()
	_draw_terrain()
	_draw_preview_path()
	_draw_cities()
	_draw_camps()
	_draw_convoys()
	_draw_armies()
	_draw_highlight()


func _unhandled_input(event: InputEvent) -> void:
	if state == null or state.map == null:
		return
	if not (event is InputEventMouseButton):
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return

	var local_pos := to_local(mouse_event.position)
	var tile := Vector2i(floori(local_pos.x / TILE), floori(local_pos.y / TILE))
	if not state.map.in_bounds(tile):
		return

	highlight = tile
	refresh()
	tile_clicked.emit(tile)
	get_viewport().set_input_as_handled()


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
			var label := "Nhà" if city.owner_side == &"player" else "Địch"
			draw_string(font, bounds.position + Vector2(4, 22), label,
					HORIZONTAL_ALIGNMENT_CENTER, bounds.size.x - 8, 13, Color(1.0, 0.90, 0.66))


func _draw_camps() -> void:
	var font: Font = ThemeDB.fallback_font
	for value: Variant in state.camps.values():
		var camp: CwCamp = value as CwCamp
		var center := _tile_center(camp.pos)
		draw_circle(center, 18.0, Color(0.95, 0.46, 0.18, 0.25))
		draw_rect(Rect2(center - Vector2(12, 10), Vector2(24, 20)), Color(0.34, 0.22, 0.10), true)
		draw_rect(Rect2(center - Vector2(12, 10), Vector2(24, 20)), Color(0.95, 0.76, 0.36), false, 2.0)
		draw_line(center + Vector2(-6, -10), center + Vector2(0, -18), Color(0.95, 0.76, 0.36), 2.0)
		if font != null:
			draw_string(font, center + Vector2(-16, 17), "Trại",
					HORIZONTAL_ALIGNMENT_CENTER, 32, 11, Color(1.0, 0.90, 0.66))


func _draw_convoys() -> void:
	var font: Font = ThemeDB.fallback_font
	for value: Variant in state.convoys.values():
		var convoy: CwConvoy = value as CwConvoy
		var center := _tile_center(convoy.pos)
		draw_rect(Rect2(center - Vector2(13, 8), Vector2(26, 16)), Color(0.78, 0.58, 0.22), true)
		draw_rect(Rect2(center - Vector2(13, 8), Vector2(26, 16)), Color(0.22, 0.14, 0.06), false, 2.0)
		draw_circle(center + Vector2(-8, 9), 4.0, Color(0.18, 0.12, 0.06))
		draw_circle(center + Vector2(8, 9), 4.0, Color(0.18, 0.12, 0.06))
		if font != null:
			draw_string(font, center + Vector2(-16, -12), "Lương",
					HORIZONTAL_ALIGNMENT_CENTER, 32, 10, Color(1.0, 0.90, 0.66))


func _draw_armies() -> void:
	var font: Font = ThemeDB.fallback_font
	for value: Variant in state.armies.values():
		var army: CwArmy = value as CwArmy
		var center := _tile_center(army.pos)
		var fill := Color(0.18, 0.32, 0.62) if army.state != &"returning" else Color(0.42, 0.44, 0.70)
		draw_circle(center, 15.0, fill)
		draw_circle(center, 15.0, Color(1.0, 0.86, 0.42), false, 2.0)
		draw_line(center + Vector2(-8, -12), center + Vector2(-8, -22), Color(0.95, 0.76, 0.36), 2.0)
		draw_polygon([
			center + Vector2(-8, -22),
			center + Vector2(8, -18),
			center + Vector2(-8, -14),
		], [Color(0.95, 0.76, 0.36)])
		if font != null:
			draw_string(font, center + Vector2(-16, 4), _general_label(army.general_id),
					HORIZONTAL_ALIGNMENT_CENTER, 32, 12, Color.WHITE)
			draw_string(font, _tile_rect(army.pos).position + Vector2(3, 34),
					str(army.troops), HORIZONTAL_ALIGNMENT_CENTER, TILE - 6, 10, Color(1.0, 0.90, 0.66))


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


func _general_label(general_id: StringName) -> String:
	if general_id == &"":
		return "ĐQ"
	return String(general_id).trim_prefix("general.").capitalize()


func _tile_rect(p: Vector2i) -> Rect2:
	return Rect2(Vector2(p.x * TILE, p.y * TILE), Vector2(TILE, TILE))


func _tile_center(p: Vector2i) -> Vector2:
	return Vector2(p.x * TILE + TILE * 0.5, p.y * TILE + TILE * 0.5)


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
