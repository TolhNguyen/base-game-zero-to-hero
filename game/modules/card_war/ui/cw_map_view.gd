class_name CwMapView
extends Node2D

signal tile_clicked(tile: Vector2i)

const TILE := 40

var state: CwState
var highlight := Vector2i(-1, -1)


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	if state == null or state.map == null:
		return

	for y: int in range(state.map.size.y):
		for x: int in range(state.map.size.x):
			var p := Vector2i(x, y)
			var rect := _tile_rect(p)
			draw_rect(rect, _terrain_color(state.map.letter_at(p)), true)
			draw_rect(rect, Color(0.08, 0.08, 0.08, 0.45), false, 1.0)

	_draw_cities()
	_draw_camps()
	_draw_convoys()
	_draw_armies()

	if state.map.in_bounds(highlight):
		draw_rect(_tile_rect(highlight).grow(-2.0), Color.WHITE, false, 3.0)


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


func _draw_cities() -> void:
	for value: Variant in state.cities.values():
		var city: CwCity = value as CwCity
		var outline := Color(0.2, 0.55, 1.0) if city.owner_side == &"player" else Color(1.0, 0.25, 0.2)
		for tile: Vector2i in city.tiles:
			draw_rect(_tile_rect(tile).grow(-3.0), outline, false, 3.0)


func _draw_camps() -> void:
	for value: Variant in state.camps.values():
		var camp: CwCamp = value as CwCamp
		var center := _tile_center(camp.pos)
		draw_rect(Rect2(center - Vector2(9, 9), Vector2(18, 18)), Color(0.1, 0.15, 0.1), true)
		draw_rect(Rect2(center - Vector2(9, 9), Vector2(18, 18)), Color(0.85, 0.95, 0.7), false, 2.0)


func _draw_convoys() -> void:
	for value: Variant in state.convoys.values():
		var convoy: CwConvoy = value as CwConvoy
		var center := _tile_center(convoy.pos)
		draw_circle(center, 8.0, Color(0.95, 0.8, 0.25))
		draw_circle(center, 5.0, Color(0.25, 0.18, 0.04))


func _draw_armies() -> void:
	var font: Font = ThemeDB.fallback_font
	for value: Variant in state.armies.values():
		var army: CwArmy = value as CwArmy
		var center := _tile_center(army.pos)
		var fill := Color(0.12, 0.32, 0.82) if army.state != &"returning" else Color(0.45, 0.45, 0.9)
		draw_circle(center, 13.0, fill)
		draw_circle(center, 13.0, Color.WHITE, false, 2.0)
		if font != null:
			var text := str(army.troops)
			draw_string(font, _tile_rect(army.pos).position + Vector2(3, 25),
					text, HORIZONTAL_ALIGNMENT_CENTER, TILE - 6, 12, Color.WHITE)


func _tile_rect(p: Vector2i) -> Rect2:
	return Rect2(Vector2(p.x * TILE, p.y * TILE), Vector2(TILE, TILE))


func _tile_center(p: Vector2i) -> Vector2:
	return Vector2(p.x * TILE + TILE * 0.5, p.y * TILE + TILE * 0.5)


func _terrain_color(letter: String) -> Color:
	match letter:
		"P":
			return Color(0.39, 0.58, 0.28)
		"F":
			return Color(0.12, 0.36, 0.18)
		"R":
			return Color(0.16, 0.45, 0.78)
		"M":
			return Color(0.36, 0.34, 0.32)
		"H":
			return Color(0.28, 0.48, 0.85)
		"E":
			return Color(0.72, 0.24, 0.18)
		_:
			return Color(0.18, 0.18, 0.18)
