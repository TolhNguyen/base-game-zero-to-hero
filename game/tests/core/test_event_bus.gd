extends GdUnitTestSuite

const BusScript := preload("res://core/events/event_bus.gd")

var _received: Array = []


func before_test() -> void:
	_received = []


func _fresh() -> Node:
	return auto_free(BusScript.new())


func _on_event(payload: Dictionary) -> void:
	_received.append(payload)


func test_publish_delivers_payload() -> void:
	var bus: Node = _fresh()
	bus.subscribe(&"test.topic", _on_event)
	bus.publish(&"test.topic", {"value": 7})
	assert_int(_received.size()).is_equal(1)
	assert_that(_received[0]).is_equal({"value": 7})


func test_publish_without_subscribers_is_noop() -> void:
	var bus: Node = _fresh()
	bus.publish(&"nobody.listens", {"x": 1})
	assert_int(_received.size()).is_equal(0)


func test_unsubscribe_stops_delivery() -> void:
	var bus: Node = _fresh()
	bus.subscribe(&"test.topic", _on_event)
	bus.unsubscribe(&"test.topic", _on_event)
	bus.publish(&"test.topic", {})
	assert_int(_received.size()).is_equal(0)


func test_multiple_subscribers_all_receive() -> void:
	var bus: Node = _fresh()
	var count := [0]
	var cb_a := func(_p: Dictionary) -> void: count[0] += 1
	var cb_b := func(_p: Dictionary) -> void: count[0] += 10
	bus.subscribe(&"multi", cb_a)
	bus.subscribe(&"multi", cb_b)
	bus.publish(&"multi", {})
	assert_int(count[0]).is_equal(11)


func test_duplicate_subscribe_delivers_once() -> void:
	var bus: Node = _fresh()
	bus.subscribe(&"dup", _on_event)
	bus.subscribe(&"dup", _on_event)
	bus.publish(&"dup", {})
	assert_int(_received.size()).is_equal(1)


func test_dead_subscriber_is_pruned_not_crashing() -> void:
	var bus: Node = _fresh()
	var victim := Node.new()
	# Bind a method of a soon-to-be-freed object.
	bus.subscribe(&"danger", Callable(victim, "queue_free"))
	victim.free()
	bus.publish(&"danger", {})
	assert_int(bus.subscriber_count(&"danger")).is_equal(0)
