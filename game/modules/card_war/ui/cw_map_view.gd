class_name CwMapView
extends Node2D

signal tile_clicked(tile: Vector2i)

const TILE := 34

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
	draw_rect(board.grow(12.0), Color(0.09, 0.075, 0.06), true)
	draw_rect(board, Color(0.22, 0.18, 0.12), true)
	draw_rect(board.grow(7.0), Color(0.31, 0.22, 0.13), false, 3.0)
	draw_rect(board.grow(2.0), Color(0.18, 0.13, 0.09), false, 1.0)


func _draw_terrain() -> void:
	for y: int in range(state.map.size.y):
		for x: int in range(state.map.size.x):
			var p := Vector2i(x, y)
			var letter := state.map.letter_at(p)
			var rect := _tile_rect(p).grow(-1.4)
			_draw_soft_tile(rect, _terrain_color(letter))
			_draw_terrain_detail(p, letter)


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
		var points := _soft_tile_points(_tile_rect(highlight).grow(-4.0))
		draw_polyline(_closed_points(points), Color(1.0, 0.82, 0.34), 2.5)


func _draw_cities() -> void:
	var font: Font = ThemeDB.fallback_font
	for value: Variant in state.cities.values():
		var city: CwCity = value as CwCity
		var fill := Color(0.14, 0.28, 0.50) if city.owner_side == &"player" else Color(0.55, 0.17, 0.15)
		var outline := Color(0.95, 0.76, 0.36) if city.owner_side == &"player" else Color(1.0, 0.48, 0.36)
		var bounds := _city_bounds(city)
		_draw_banner(bounds.grow(-5.0), fill, outline)
		if font != null:
			var label := "Nhà" if city.owner_side == &"player" else "Địch"
			draw_string(font, bounds.position + Vector2(3, bounds.size.y * 0.48 + 5), label,
					HORIZONTAL_ALIGNMENT_CENTER, bounds.size.x - 6, 13, Color(1.0, 0.92, 0.70))


func _draw_camps() -> void:
	var font: Font = ThemeDB.fallback_font
	for value: Variant in state.camps.values():
		var camp: CwCamp = value as CwCamp
		var center := _tile_center(camp.pos)
		draw_circle(center, 15.0, Color(0.95, 0.46, 0.18, 0.22))
		draw_polygon([
			center + Vector2(-13, 8),
			center + Vector2(0, -13),
			center + Vector2(13, 8),
		], [Color(0.36, 0.22, 0.11)])
		draw_polyline(PackedVector2Array([
			center + Vector2(-13, 8),
			center + Vector2(0, -13),
			center + Vector2(13, 8),
			center + Vector2(-13, 8),
		]), Color(0.95, 0.76, 0.36), 2.0)
		draw_line(center + Vector2(-4, -12), center + Vector2(-4, -22), Color(0.95, 0.76, 0.36), 1.8)
		if font != null:
			draw_string(font, center + Vector2(-16, 12), "Trại",
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
		draw_circle(center, 13.5, Color(0.07, 0.05, 0.035, 0.40))
		draw_circle(center + Vector2(0, -1), 12.5, fill)
		draw_circle(center + Vector2(0, -1), 12.5, Color(1.0, 0.86, 0.42), false, 2.0)
		draw_line(center + Vector2(-7, -11), center + Vector2(-7, -20), Color(0.95, 0.76, 0.36), 1.8)
		draw_polygon([
			center + Vector2(-7, -20),
			center + Vector2(7, -17),
			center + Vector2(-7, -14),
		], [Color(0.95, 0.76, 0.36)])
		if font != null:
			draw_string(font, center + Vector2(-16, 1), _general_label(army.general_id),
					HORIZONTAL_ALIGNMENT_CENTER, 32, 12, Color.WHITE)
			draw_string(font, _tile_rect(army.pos).position + Vector2(2, 28),
					str(army.troops), HORIZONTAL_ALIGNMENT_CENTER, TILE - 4, 9, Color(1.0, 0.90, 0.66))


func _draw_soft_tile(rect: Rect2, fill: Color) -> void:
	var points := _soft_tile_points(rect)
	draw_colored_polygon(points, fill)
	draw_polyline(_closed_points(points), Color(0.95, 0.85, 0.62, 0.10), 1.0)


func _draw_terrain_detail(tile: Vector2i, letter: String) -> void:
	var center := _tile_center(tile)
	match letter:
		"F":
			draw_circle(center + Vector2(-5, 1), 3.0, Color(0.08, 0.22, 0.11, 0.65))
			draw_circle(center + Vector2(3, -3), 3.5, Color(0.10, 0.26, 0.13, 0.60))
		"R":
			draw_line(center + Vector2(-12, 0), center + Vector2(12, -1),
					Color(0.55, 0.78, 0.82, 0.42), 2.0)
			draw_line(center + Vector2(-8, 5), center + Vector2(8, 4),
					Color(0.18, 0.28, 0.34, 0.38), 1.5)
		"M":
			draw_polygon([
				center + Vector2(-8, 7),
				center + Vector2(0, -7),
				center + Vector2(8, 7),
			], [Color(0.52, 0.50, 0.45, 0.38)])
		"H":
			draw_circle(center, 5.0, Color(0.43, 0.50, 0.64, 0.30))


func _draw_banner(bounds: Rect2, fill: Color, outline: Color) -> void:
	var points := PackedVector2Array([
		bounds.position + Vector2(4, 0),
		bounds.position + Vector2(bounds.size.x - 4, 0),
		bounds.position + Vector2(bounds.size.x, bounds.size.y * 0.5),
		bounds.position + Vector2(bounds.size.x - 4, bounds.size.y),
		bounds.position + Vector2(4, bounds.size.y),
		bounds.position + Vector2(0, bounds.size.y * 0.5),
	])
	draw_colored_polygon(points, fill)
	draw_polyline(_closed_points(points), outline, 2.4)


func _soft_tile_points(rect: Rect2) -> PackedVector2Array:
	var cut := rect.size.x * 0.18
	return PackedVector2Array([
		rect.position + Vector2(cut, 0),
		rect.position + Vector2(rect.size.x - cut, 0),
		rect.position + Vector2(rect.size.x, cut),
		rect.position + Vector2(rect.size.x, rect.size.y - cut),
		rect.position + Vector2(rect.size.x - cut, rect.size.y),
		rect.position + Vector2(cut, rect.size.y),
		rect.position + Vector2(0, rect.size.y - cut),
		rect.position + Vector2(0, cut),
	])


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	if not closed.is_empty():
		closed.append(closed[0])
	return closed


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
			return Color(0.50, 0.45, 0.30)
		"F":
			return Color(0.17, 0.35, 0.20)
		"R":
			return Color(0.19, 0.36, 0.43)
		"M":
			return Color(0.35, 0.33, 0.30)
		"H":
			return Color(0.23, 0.33, 0.50)
		"E":
			return Color(0.45, 0.20, 0.18)
		_:
			return Color(0.12, 0.12, 0.12)
