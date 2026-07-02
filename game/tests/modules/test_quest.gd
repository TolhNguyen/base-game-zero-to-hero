extends GdUnitTestSuite

const TrackerScript := preload("res://modules/quest_lite/quest_tracker.gd")
const RegistryScript := preload("res://core/registry/registry.gd")
const BusScript := preload("res://core/events/event_bus.gd")

var _completed: Array = []


func before_test() -> void:
	_completed = []


func _wired() -> Array:  # [tracker, bus]
	var tracker: QuestTracker = auto_free(TrackerScript.new())
	var reg: Node = auto_free(RegistryScript.new())
	reg.scan("res://tests/fixtures/quest")
	var bus: Node = auto_free(BusScript.new())
	bus.subscribe(&"quest.completed", func(p: Dictionary) -> void: _completed.append(p))
	tracker.registry = reg
	tracker.bus = bus
	return [tracker, bus]


func test_start_and_progress_via_topic() -> void:
	var pair := _wired()
	var tracker: QuestTracker = pair[0]
	var bus: Node = pair[1]
	assert_int(tracker.start_quest(&"quest.test_collect")).is_equal(OK)
	assert_bool(tracker.is_active(&"quest.test_collect")).is_true()

	bus.publish(&"test.thing_collected", {})
	bus.publish(&"test.thing_collected", {})
	assert_int(tracker.progress(&"quest.test_collect")).is_equal(2)
	assert_bool(tracker.is_completed(&"quest.test_collect")).is_false()


func test_completion_publishes_exactly_once() -> void:
	var pair := _wired()
	var tracker: QuestTracker = pair[0]
	var bus: Node = pair[1]
	tracker.start_quest(&"quest.test_collect")
	for i in range(5):  # two more than required
		bus.publish(&"test.thing_collected", {})
	assert_bool(tracker.is_completed(&"quest.test_collect")).is_true()
	assert_int(tracker.progress(&"quest.test_collect")).is_equal(3)  # frozen at required
	assert_int(_completed.size()).is_equal(1)
	assert_str(String(_completed[0]["id"])).is_equal("quest.test_collect")


func test_unknown_quest_errors() -> void:
	var pair := _wired()
	var tracker: QuestTracker = pair[0]
	assert_int(tracker.start_quest(&"quest.missing")).is_equal(ERR_DOES_NOT_EXIST)


func test_double_start_rejected() -> void:
	var pair := _wired()
	var tracker: QuestTracker = pair[0]
	tracker.start_quest(&"quest.test_collect")
	assert_int(tracker.start_quest(&"quest.test_collect")).is_equal(ERR_ALREADY_IN_USE)


func test_capture_restore_keeps_progress_and_resubscribes() -> void:
	var pair := _wired()
	var tracker: QuestTracker = pair[0]
	var bus: Node = pair[1]
	tracker.start_quest(&"quest.test_collect")
	bus.publish(&"test.thing_collected", {})
	var snapshot := tracker.capture()

	var pair2 := _wired()
	var tracker2: QuestTracker = pair2[0]
	var bus2: Node = pair2[1]
	tracker2.restore(snapshot)
	assert_int(tracker2.progress(&"quest.test_collect")).is_equal(1)
	assert_bool(tracker2.is_active(&"quest.test_collect")).is_true()
	# restored quest keeps counting on the new bus
	bus2.publish(&"test.thing_collected", {})
	bus2.publish(&"test.thing_collected", {})
	assert_bool(tracker2.is_completed(&"quest.test_collect")).is_true()
