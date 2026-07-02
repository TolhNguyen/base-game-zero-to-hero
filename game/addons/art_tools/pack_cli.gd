extends SceneTree
## CLI: packs art_incoming/<set>/ into game/assets/sprites/.
## Run via: bash tools/art_pack.sh <set>
## (godot --headless --path game -s res://addons/art_tools/pack_cli.gd -- <set>)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("usage: art_pack <set_name>")
		quit(2)
		return
	var set_name: String = args[0]
	var incoming := ProjectSettings.globalize_path("res://").path_join("../art_incoming").path_join(set_name)
	var packer := SheetPacker.new()
	var loaded := packer.load_set(incoming, set_name)
	var issues: Array = loaded["issues"]
	if not issues.is_empty():
		printerr("art_pack: %d spec violation(s) in %s:" % [issues.size(), incoming])
		for issue: String in issues:
			printerr("  - " + issue)
		quit(1)
		return
	var frames: Dictionary = loaded["frames"]
	if frames.is_empty():
		printerr("art_pack: no valid frames found in %s" % incoming)
		quit(1)
		return
	var packed := packer.pack(frames)
	DirAccess.make_dir_recursive_absolute("res://assets/sprites")
	var sheet_res := "res://assets/sprites/%s_sheet.png" % set_name
	var sheet_err: int = (packed["image"] as Image).save_png(
		ProjectSettings.globalize_path(sheet_res))
	if sheet_err != OK:
		printerr("art_pack: failed to save sheet (%d)" % sheet_err)
		quit(1)
		return
	var tres_text: String = packer.build_spriteframes_tres(sheet_res, packed["regions"])
	var tres_path := "res://assets/sprites/%s_frames.tres" % set_name
	var f := FileAccess.open(tres_path, FileAccess.WRITE)
	f.store_string(tres_text)
	f.close()
	var anim_count: int = packed["regions"].size()
	print("art_pack: OK — %s (%d animations) -> %s + %s"
		% [set_name, anim_count, sheet_res, tres_path])
	print("art_pack: next: open in editor to eyeball, then commit to approve.")
	quit(0)
