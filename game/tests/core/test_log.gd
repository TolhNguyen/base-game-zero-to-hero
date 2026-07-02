extends GdUnitTestSuite

const LogScript := preload("res://core/debug/log.gd")


func _fresh() -> Node:
	# A detached instance: _ready never runs, so no file IO in unit tests.
	return auto_free(LogScript.new())


func test_level_filtering() -> void:
	var log_svc: Node = _fresh()
	log_svc.min_level = log_svc.Level.WARN
	log_svc.debug("hidden")
	log_svc.info("hidden too")
	log_svc.warn("visible")
	var recent: Array[Dictionary] = log_svc.get_recent()
	assert_int(recent.size()).is_equal(1)
	assert_str(recent[0]["msg"]).is_equal("visible")


func test_ring_buffer_capacity() -> void:
	var log_svc: Node = _fresh()
	log_svc.ring_capacity = 5
	for i in range(10):
		log_svc.info("msg %d" % i)
	var recent: Array[Dictionary] = log_svc.get_recent()
	assert_int(recent.size()).is_equal(5)
	assert_str(recent[0]["msg"]).is_equal("msg 5")
	assert_str(recent[4]["msg"]).is_equal("msg 9")


func test_context_is_stored() -> void:
	var log_svc: Node = _fresh()
	log_svc.error("boom", {"code": 42})
	var recent: Array[Dictionary] = log_svc.get_recent(1)
	assert_that(recent[0]["ctx"]).is_equal({"code": 42})


func test_get_recent_count_limits() -> void:
	var log_svc: Node = _fresh()
	for i in range(4):
		log_svc.info("m%d" % i)
	assert_int(log_svc.get_recent(2).size()).is_equal(2)
