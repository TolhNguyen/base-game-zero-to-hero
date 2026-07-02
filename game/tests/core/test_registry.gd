extends GdUnitTestSuite

const RegistryScript := preload("res://core/registry/registry.gd")
const FIXTURES := "res://tests/fixtures/registry"


func _fresh() -> Node:
	return auto_free(RegistryScript.new())


func test_scan_indexes_definitions_recursively() -> void:
	var reg: Node = _fresh()
	assert_int(reg.scan(FIXTURES + "/valid")).is_equal(OK)
	assert_int(reg.count()).is_equal(3)
	assert_bool(reg.has_def(&"item.apple")).is_true()
	assert_bool(reg.has_def(&"item.sword")).is_true()  # from sub/
	assert_bool(reg.has_def(&"scene.home")).is_true()


func test_get_def_returns_definition() -> void:
	var reg: Node = _fresh()
	reg.scan(FIXTURES + "/valid")
	var def: Definition = reg.get_def(&"item.apple")
	assert_object(def).is_not_null()
	assert_str(String(def.id)).is_equal("item.apple")


func test_unknown_id_returns_null() -> void:
	var reg: Node = _fresh()
	reg.scan(FIXTURES + "/valid")
	assert_object(reg.get_def(&"item.does_not_exist")).is_null()


func test_ids_with_prefix() -> void:
	var reg: Node = _fresh()
	reg.scan(FIXTURES + "/valid")
	var items: Array[StringName] = reg.ids_with_prefix("item.")
	assert_int(items.size()).is_equal(2)
	assert_that(items).contains([&"item.apple", &"item.sword"])


func test_duplicate_id_is_hard_error() -> void:
	var reg: Node = _fresh()
	assert_int(reg.scan(FIXTURES + "/duplicate")).is_equal(ERR_ALREADY_EXISTS)


func test_empty_id_is_hard_error() -> void:
	var reg: Node = _fresh()
	assert_int(reg.scan(FIXTURES + "/empty_id")).is_equal(ERR_INVALID_DATA)


func test_failed_scan_preserves_previous_index() -> void:
	var reg: Node = _fresh()
	reg.scan(FIXTURES + "/valid")
	assert_int(reg.scan(FIXTURES + "/duplicate")).is_equal(ERR_ALREADY_EXISTS)
	assert_int(reg.count()).is_equal(3)
	assert_bool(reg.has_def(&"item.apple")).is_true()


func test_rescan_clears_previous_state() -> void:
	var reg: Node = _fresh()
	reg.scan(FIXTURES + "/valid")
	assert_int(reg.count()).is_equal(3)
	reg.scan(FIXTURES + "/valid")
	assert_int(reg.count()).is_equal(3)
