extends GdUnitTestSuite

const InventoryScript := preload("res://modules/inventory/inventory.gd")
const RegistryScript := preload("res://core/registry/registry.gd")
const BusScript := preload("res://core/events/event_bus.gd")

var _events: Array = []


func before_test() -> void:
	_events = []


func _wired() -> Inventory:
	var inv: Inventory = auto_free(InventoryScript.new())
	var reg: Node = auto_free(RegistryScript.new())
	reg.scan("res://tests/fixtures/inventory")
	var bus: Node = auto_free(BusScript.new())
	bus.subscribe(&"inventory.changed", func(p: Dictionary) -> void: _events.append(p))
	inv.registry = reg
	inv.bus = bus
	return inv


func test_add_and_count() -> void:
	var inv := _wired()
	assert_int(inv.add(&"item.test_apple", 2)).is_equal(0)
	assert_int(inv.count(&"item.test_apple")).is_equal(2)


func test_stack_limit_returns_remainder() -> void:
	var inv := _wired()
	# max_stack of item.test_apple is 3 (fixture)
	assert_int(inv.add(&"item.test_apple", 5)).is_equal(2)
	assert_int(inv.count(&"item.test_apple")).is_equal(3)
	# stack already full: everything overflows
	assert_int(inv.add(&"item.test_apple", 1)).is_equal(1)


func test_unknown_item_gets_default_stack() -> void:
	var inv := _wired()
	assert_int(inv.add(&"item.unregistered", 50)).is_equal(0)
	assert_int(inv.count(&"item.unregistered")).is_equal(50)


func test_remove_returns_actual_amount() -> void:
	var inv := _wired()
	inv.add(&"item.test_apple", 3)
	assert_int(inv.remove(&"item.test_apple", 2)).is_equal(2)
	assert_int(inv.remove(&"item.test_apple", 5)).is_equal(1)
	assert_int(inv.count(&"item.test_apple")).is_equal(0)
	assert_int(inv.remove(&"item.test_apple", 1)).is_equal(0)


func test_changed_topic_published_with_totals() -> void:
	var inv := _wired()
	inv.add(&"item.test_apple", 2)
	inv.remove(&"item.test_apple", 1)
	assert_int(_events.size()).is_equal(2)
	assert_int(_events[0]["delta"]).is_equal(2)
	assert_int(_events[1]["delta"]).is_equal(-1)
	assert_int(_events[1]["total"]).is_equal(1)


func test_capture_restore_round_trip() -> void:
	var inv := _wired()
	inv.add(&"item.test_apple", 2)
	inv.add(&"item.unregistered", 7)
	var snapshot := inv.capture()

	var other := _wired()
	other.restore(snapshot)
	assert_int(other.count(&"item.test_apple")).is_equal(2)
	assert_int(other.count(&"item.unregistered")).is_equal(7)
	assert_that(other.item_ids()).contains([&"item.test_apple", &"item.unregistered"])
