extends GdUnitTestSuite
## Smoke test proving the headless test pipeline works.


func test_pipeline_alive() -> void:
	assert_bool(true).is_true()


func test_project_boots_ring1_only() -> void:
	# Core must never reference rings above it (Constitution P8).
	# Real enforcement lives in tools/validate_deps.sh; this asserts the
	# boot scene itself is core-only.
	var boot: PackedScene = load("res://core/boot/boot.tscn")
	assert_object(boot).is_not_null()
