extends GdUnitTestSuite

const FlowScript := preload("res://core/scene_flow/scene_flow.gd")
const RegistryScript := preload("res://core/registry/registry.gd")
const BusScript := preload("res://core/events/event_bus.gd")

var _events: Array = []


func before_test() -> void:
	_events = []


func _wired_flow(change_result: Error = OK) -> Node:
	var flow: Node = auto_free(FlowScript.new())
	var reg: Node = auto_free(RegistryScript.new())
	reg.scan("res://tests/fixtures/scene_flow")
	var bus: Node = auto_free(BusScript.new())
	bus.subscribe(&"scene.about_to_change",
		func(p: Dictionary) -> void: _events.append(["about_to_change", p]))
	bus.subscribe(&"scene.changed",
		func(p: Dictionary) -> void: _events.append(["changed", p]))
	flow.registry = reg
	flow.bus = bus
	flow.change_fn = func(_path: String) -> Error: return change_result
	return flow


func test_goto_scene_resolves_and_emits_in_order() -> void:
	var flow: Node = _wired_flow()
	assert_int(flow.goto_scene(&"scene.test_boot", &"door_a")).is_equal(OK)
	assert_int(_events.size()).is_equal(2)
	assert_str(_events[0][0]).is_equal("about_to_change")
	assert_str(_events[1][0]).is_equal("changed")
	assert_str(String(_events[1][1]["spawn_point"])).is_equal("door_a")
	assert_str(String(flow.current_scene_id())).is_equal("scene.test_boot")


func test_default_spawn_used_when_unspecified() -> void:
	var flow: Node = _wired_flow()
	flow.goto_scene(&"scene.test_boot")
	assert_str(String(_events[0][1]["spawn_point"])).is_equal("entry")


func test_unknown_id_errors_without_events() -> void:
	var flow: Node = _wired_flow()
	assert_int(flow.goto_scene(&"scene.nope")).is_equal(ERR_DOES_NOT_EXIST)
	assert_int(_events.size()).is_equal(0)
	assert_str(String(flow.current_scene_id())).is_equal("")


func test_non_scene_definition_is_rejected() -> void:
	var flow: Node = _wired_flow()
	assert_int(flow.goto_scene(&"item.not_a_scene")).is_equal(ERR_INVALID_DATA)
	assert_int(_events.size()).is_equal(0)


func test_failed_switch_keeps_state_and_skips_changed_event() -> void:
	var flow: Node = _wired_flow(ERR_CANT_OPEN)
	assert_int(flow.goto_scene(&"scene.test_boot")).is_equal(ERR_CANT_OPEN)
	assert_int(_events.size()).is_equal(1)  # only about_to_change
	assert_str(String(flow.current_scene_id())).is_equal("")
