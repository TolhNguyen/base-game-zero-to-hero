extends GdUnitTestSuite

const BoxScene := preload("res://modules/dialogue/dialogue_box.tscn")
const RegistryScript := preload("res://core/registry/registry.gd")
const BusScript := preload("res://core/events/event_bus.gd")

var _topics: Array = []


func before_test() -> void:
	_topics = []


func _wired_box() -> CanvasLayer:
	var box: CanvasLayer = auto_free(BoxScene.instantiate())
	var reg: Node = auto_free(RegistryScript.new())
	reg.scan("res://tests/fixtures/dialogue")
	var bus: Node = auto_free(BusScript.new())
	bus.subscribe(&"dialogue.started",
		func(p: Dictionary) -> void: _topics.append(["started", p]))
	bus.subscribe(&"dialogue.finished",
		func(p: Dictionary) -> void: _topics.append(["finished", p]))
	box.registry = reg
	box.bus = bus
	add_child(box)
	return box


func test_start_shows_first_line_and_publishes() -> void:
	var box: CanvasLayer = _wired_box()
	assert_int(box.start(&"dialogue.test_greeting")).is_equal(OK)
	assert_bool(box.visible).is_true()
	assert_bool(box.is_active()).is_true()
	assert_str(box.get_node("%Speaker").text).is_equal("Elder")
	assert_str(box.get_node("%Text").text).is_equal("Hello, traveler.")
	assert_int(_topics.size()).is_equal(1)
	assert_str(_topics[0][0]).is_equal("started")


func test_unknown_id_errors() -> void:
	var box: CanvasLayer = _wired_box()
	assert_int(box.start(&"dialogue.missing")).is_equal(ERR_DOES_NOT_EXIST)
	assert_bool(box.is_active()).is_false()


func test_non_dialogue_def_rejected() -> void:
	var box: CanvasLayer = _wired_box()
	assert_int(box.start(&"item.decoy")).is_equal(ERR_INVALID_DATA)


func test_advance_steps_and_finishes() -> void:
	var box: CanvasLayer = _wired_box()
	box.start(&"dialogue.test_greeting")
	box.advance()
	assert_str(box.get_node("%Text").text).is_equal("Bring me three apples.")
	box.advance()  # line without speaker
	assert_str(box.get_node("%Text").text).is_equal("Good luck!")
	assert_bool(box.get_node("%Speaker").visible).is_false()
	box.advance()  # past the end -> finished
	assert_bool(box.is_active()).is_false()
	assert_bool(box.visible).is_false()
	assert_str(_topics[-1][0]).is_equal("finished")
	assert_str(String(_topics[-1][1]["id"])).is_equal("dialogue.test_greeting")


func test_advance_while_inactive_is_noop() -> void:
	var box: CanvasLayer = _wired_box()
	box.advance()
	assert_bool(box.is_active()).is_false()
	assert_int(_topics.size()).is_equal(0)
