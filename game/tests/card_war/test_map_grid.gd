extends GdUnitTestSuite

const GridScript := preload("res://modules/card_war/sim/cw_map_grid.gd")

const COSTS := {"P": 2, "F": 3, "R": 0, "M": 0, "H": 2, "E": 2}


func _grid(rows: PackedStringArray) -> CwMapGrid:
	return GridScript.from_rows(rows, COSTS)


func test_size_and_costs() -> void:
	var g: CwMapGrid = _grid(PackedStringArray(["PF", "RM"]))
	assert_that(g.size).is_equal(Vector2i(2, 2))
	assert_int(g.move_cost(Vector2i(0, 0))).is_equal(2)
	assert_int(g.move_cost(Vector2i(1, 0))).is_equal(3)
	assert_int(g.move_cost(Vector2i(0, 1))).is_equal(0)
	assert_bool(g.in_bounds(Vector2i(2, 0))).is_false()
	assert_str(g.letter_at(Vector2i(1, 1))).is_equal("M")


func test_path_straight_line() -> void:
	var g: CwMapGrid = _grid(PackedStringArray(["PPPP"]))
	var path: Array[Vector2i] = g.find_path(Vector2i(0, 0), Vector2i(3, 0))
	assert_that(path).is_equal([Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)])


func test_path_avoids_impassable_river() -> void:
	# P P P
	# R R P   -> must go around via x=2
	# P P P
	var g: CwMapGrid = _grid(PackedStringArray(["PPP", "RRP", "PPP"]))
	var path: Array[Vector2i] = g.find_path(Vector2i(0, 0), Vector2i(0, 2))
	assert_bool(path.size() > 0).is_true()
	for p: Vector2i in path:
		assert_int(g.move_cost(p)).is_not_equal(0)
	assert_that(path[path.size() - 1]).is_equal(Vector2i(0, 2))


func test_path_prefers_cheap_terrain() -> void:
	# Direct route through five F tiles costs 17; bottom-row detour costs 16.
	var g: CwMapGrid = _grid(PackedStringArray(["PFFFFFP", "PPPPPPP"]))
	var path: Array[Vector2i] = g.find_path(Vector2i(0, 0), Vector2i(6, 0))
	assert_that(path).is_equal([
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(2, 1),
		Vector2i(3, 1),
		Vector2i(4, 1),
		Vector2i(5, 1),
		Vector2i(6, 1),
		Vector2i(6, 0),
	])


func test_unreachable_returns_empty() -> void:
	var g: CwMapGrid = _grid(PackedStringArray(["PMP"]))
	assert_that(g.find_path(Vector2i(0, 0), Vector2i(2, 0))).is_equal([] as Array[Vector2i])


func test_invalid_path_inputs_return_empty() -> void:
	var g: CwMapGrid = _grid(PackedStringArray(["PM", "RP"]))
	assert_that(g.find_path(Vector2i(-1, 0), Vector2i(1, 1))).is_equal([] as Array[Vector2i])
	assert_that(g.find_path(Vector2i(0, 0), Vector2i(2, 0))).is_equal([] as Array[Vector2i])
	assert_that(g.find_path(Vector2i(1, 0), Vector2i(1, 1))).is_equal([] as Array[Vector2i])
	assert_that(g.find_path(Vector2i(0, 0), Vector2i(0, 1))).is_equal([] as Array[Vector2i])


func test_turns_for_path() -> void:
	var g: CwMapGrid = _grid(PackedStringArray(["PPPPPPPP"]))
	var path: Array[Vector2i] = g.find_path(Vector2i(0, 0), Vector2i(7, 0))
	# 7 tiles x cost 2 = 14 points, 6 points/turn -> 3 turns
	assert_int(g.turns_for_path(path, 6)).is_equal(3)


func test_tiles_with_letter() -> void:
	var g: CwMapGrid = _grid(PackedStringArray(["PH", "HP"]))
	var tiles: Array[Vector2i] = g.tiles_with_letter("H")
	assert_that(tiles).contains([Vector2i(1, 0), Vector2i(0, 1)])
