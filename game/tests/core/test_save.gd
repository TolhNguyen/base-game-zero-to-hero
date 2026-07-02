extends GdUnitTestSuite

const SaveScript := preload("res://core/save/save_service.gd")

const TEST_SLOT := 900  # high slot numbers to avoid clobbering real saves


class StubProvider:
	var state: Dictionary = {}

	func capture() -> Dictionary:
		return state.duplicate(true)

	func restore(data: Dictionary) -> void:
		state = data.duplicate(true)


func _fresh() -> Node:
	return auto_free(SaveScript.new())


func after_test() -> void:
	for slot in [TEST_SLOT, TEST_SLOT + 1]:
		var path := "user://saves/slot_%d.json" % slot
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func test_round_trip_single_provider() -> void:
	var svc: Node = _fresh()
	var prov := StubProvider.new()
	prov.state = {"hp": 10, "name": "hero"}
	svc.register_provider(&"player", prov)
	assert_int(svc.save_game(TEST_SLOT)).is_equal(OK)

	prov.state = {}
	assert_int(svc.load_game(TEST_SLOT)).is_equal(OK)
	assert_that(prov.state).is_equal({"hp": 10.0, "name": "hero"})


func test_multiple_providers_are_isolated() -> void:
	var svc: Node = _fresh()
	var a := StubProvider.new()
	var b := StubProvider.new()
	a.state = {"gold": 5}
	b.state = {"scene": "village"}
	svc.register_provider(&"wallet", a)
	svc.register_provider(&"world", b)
	svc.save_game(TEST_SLOT)

	a.state = {}
	b.state = {}
	svc.load_game(TEST_SLOT)
	assert_that(a.state).is_equal({"gold": 5.0})
	assert_that(b.state).is_equal({"scene": "village"})


func test_missing_slot_returns_error() -> void:
	var svc: Node = _fresh()
	assert_int(svc.load_game(998877)).is_equal(ERR_DOES_NOT_EXIST)


func test_forward_migration_runs() -> void:
	# Write a v0 file by hand: old layout had player data at top level.
	DirAccess.make_dir_recursive_absolute("user://saves")
	var file := FileAccess.open("user://saves/slot_%d.json" % TEST_SLOT, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version": 0, "hp": 3}))
	file.close()

	var svc: Node = _fresh()
	var migs: Array[Callable] = [
		func(doc: Dictionary) -> Dictionary:
			return {"data": {"player": {"hp": doc["hp"]}}},
	]
	svc.migrations = migs
	var prov := StubProvider.new()
	svc.register_provider(&"player", prov)
	assert_int(svc.load_game(TEST_SLOT)).is_equal(OK)
	assert_that(prov.state).is_equal({"hp": 3.0})


func test_future_schema_is_refused() -> void:
	DirAccess.make_dir_recursive_absolute("user://saves")
	var file := FileAccess.open("user://saves/slot_%d.json" % TEST_SLOT, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version": 999, "data": {}}))
	file.close()

	var svc: Node = _fresh()
	assert_int(svc.load_game(TEST_SLOT)).is_equal(ERR_INVALID_DATA)


func test_corrupt_file_is_refused() -> void:
	DirAccess.make_dir_recursive_absolute("user://saves")
	var file := FileAccess.open("user://saves/slot_%d.json" % TEST_SLOT, FileAccess.WRITE)
	file.store_string("this is not json {")
	file.close()

	var svc: Node = _fresh()
	assert_int(svc.load_game(TEST_SLOT)).is_equal(ERR_FILE_CORRUPT)


func test_list_and_delete_slots() -> void:
	var svc: Node = _fresh()
	svc.register_provider(&"p", StubProvider.new())
	svc.save_game(TEST_SLOT)
	svc.save_game(TEST_SLOT + 1)
	var slots: Array[int] = svc.list_slots()
	assert_that(slots).contains([TEST_SLOT, TEST_SLOT + 1])
	assert_int(svc.delete_slot(TEST_SLOT)).is_equal(OK)
	assert_bool(svc.list_slots().has(TEST_SLOT)).is_false()
	assert_int(svc.delete_slot(TEST_SLOT)).is_equal(ERR_DOES_NOT_EXIST)
