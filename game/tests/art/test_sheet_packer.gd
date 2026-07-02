extends GdUnitTestSuite

const PackerScript := preload("res://addons/art_tools/sheet_packer.gd")


func _packer() -> SheetPacker:
	return PackerScript.new()


func _frame(size: Vector2i = Vector2i(64, 64), color: Color = Color(1, 0, 0, 0.5)) -> Image:
	var img := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return img


func test_parse_name_accepts_spec_names() -> void:
	var p := _packer()
	var parts: Array = p.parse_name("elder_walk_left_03.png")
	assert_that(parts).is_equal(["elder", "walk", "left", 3])


func test_parse_name_rejects_bad_names() -> void:
	var p := _packer()
	assert_bool(p.parse_name("Elder_Walk_left_3.png").is_empty()).is_true()
	assert_bool(p.parse_name("elder_walk_north_00.png").is_empty()).is_true()
	assert_bool(p.parse_name("elder_walk_left.png").is_empty()).is_true()


func test_load_set_flags_spec_violations() -> void:
	var dir := "user://art_test_bad"
	DirAccess.make_dir_recursive_absolute(dir)
	_frame(Vector2i(32, 32)).save_png(
		ProjectSettings.globalize_path(dir + "/hero_idle_down_00.png"))
	var opaque := Image.create_empty(64, 64, false, Image.FORMAT_RGB8)
	opaque.fill(Color.RED)
	opaque.save_png(ProjectSettings.globalize_path(dir + "/hero_idle_down_01.png"))
	_frame().save_png(ProjectSettings.globalize_path(dir + "/WRONG-name.png"))

	var result: Dictionary = _packer().load_set(
		ProjectSettings.globalize_path(dir), "hero")
	var issues: Array = result["issues"]
	assert_int(issues.size()).is_equal(3)  # wrong size, no alpha, bad name
	assert_bool(result["frames"].is_empty()).is_true()


func test_load_set_orders_frames_by_index() -> void:
	var dir := "user://art_test_ok"
	DirAccess.make_dir_recursive_absolute(dir)
	# write out of order on purpose
	_frame(Vector2i(64, 64), Color(0, 0, 1, 0.5)).save_png(
		ProjectSettings.globalize_path(dir + "/hero_idle_down_01.png"))
	_frame(Vector2i(64, 64), Color(1, 0, 0, 0.5)).save_png(
		ProjectSettings.globalize_path(dir + "/hero_idle_down_00.png"))

	var result: Dictionary = _packer().load_set(
		ProjectSettings.globalize_path(dir), "hero")
	assert_bool(result["issues"].is_empty()).is_true()
	var imgs: Array = result["frames"]["idle_down"]
	assert_int(imgs.size()).is_equal(2)
	# frame 00 is red-ish, frame 01 blue-ish
	assert_float(imgs[0].get_pixel(2, 2).r).is_greater(0.9)
	assert_float(imgs[1].get_pixel(2, 2).b).is_greater(0.9)


func test_pack_geometry_rows_per_animation() -> void:
	var fs := Vector2i(8, 8)
	var frames := {
		"idle_down": [_frame(fs), _frame(fs)] as Array[Image],
		"walk_down": [_frame(fs), _frame(fs), _frame(fs)] as Array[Image],
	}
	var packed: Dictionary = _packer().pack(frames, fs)
	var sheet: Image = packed["image"]
	assert_int(sheet.get_width()).is_equal(24)   # widest row: 3 frames
	assert_int(sheet.get_height()).is_equal(16)  # 2 rows
	var regions: Dictionary = packed["regions"]
	assert_that(regions["idle_down"][1]).is_equal(Rect2i(8, 0, 8, 8))
	assert_that(regions["walk_down"][2]).is_equal(Rect2i(16, 8, 8, 8))


func test_spriteframes_tres_text_structure() -> void:
	var fs := Vector2i(8, 8)
	var frames := {"idle_down": [_frame(fs)] as Array[Image]}
	var packed: Dictionary = _packer().pack(frames, fs)
	var text: String = _packer().build_spriteframes_tres(
		"res://assets/sprites/x_sheet.png", packed["regions"])
	assert_bool(text.contains("type=\"SpriteFrames\"")).is_true()
	assert_bool(text.contains("&\"idle_down\"")).is_true()
	assert_bool(text.contains("Rect2(0, 0, 8, 8)")).is_true()
	assert_bool(text.contains("res://assets/sprites/x_sheet.png")).is_true()


func test_sample_assets_load_if_present() -> void:
	# End-to-end proof: the committed sample set (packed by tools/art_pack.sh)
	# must load as a real SpriteFrames with all 8 animations.
	if not ResourceLoader.exists("res://assets/sprites/sample_frames.tres"):
		return  # sample not packed yet (pre-T5)
	var sf: SpriteFrames = load("res://assets/sprites/sample_frames.tres")
	assert_object(sf).is_not_null()
	for anim in ["idle_down", "idle_left", "idle_right", "idle_up",
			"walk_down", "walk_left", "walk_right", "walk_up"]:
		assert_bool(sf.has_animation(anim))\
			.override_failure_message("missing animation: %s" % anim).is_true()
	assert_int(sf.get_frame_count("walk_down")).is_equal(6)
