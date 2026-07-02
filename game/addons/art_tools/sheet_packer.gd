class_name SheetPacker
extends RefCounted
## Packs validated frame PNGs (docs/art/asset-spec.md) into one sprite
## sheet + a SpriteFrames .tres with atlas regions. Pure logic — the CLI
## wrapper is pack_cli.gd; tests drive these methods directly.

const FRAME_SIZE := Vector2i(64, 64)
const ANIM_FPS := {"idle": 6.0, "walk": 10.0}

var _name_regex := RegEx.create_from_string(
	"^([a-z0-9]+)_([a-z0-9]+)_(down|left|right|up)_(\\d{2})\\.png$")


## Returns [set, anim, dir, index] or empty array if the name is invalid.
func parse_name(filename: String) -> Array:
	var m := _name_regex.search(filename)
	if m == null:
		return []
	return [m.get_string(1), m.get_string(2), m.get_string(3), int(m.get_string(4))]


## Loads a set directory (absolute path). Returns:
## {"issues": Array[String], "frames": {"anim_dir": Array[Image] ordered}}
func load_set(dir_path: String, expected_set: String,
		frame_size: Vector2i = FRAME_SIZE) -> Dictionary:
	var issues: Array[String] = []
	var buckets := {}  # "anim_dir" -> Array of [index, Image]
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return {"issues": ["cannot open directory: %s" % dir_path], "frames": {}}
	for filename in dir.get_files():
		if not filename.ends_with(".png"):
			continue
		var parts := parse_name(filename)
		if parts.is_empty():
			issues.append("bad name (spec: <set>_<anim>_<dir>_<NN>.png): %s" % filename)
			continue
		if parts[0] != expected_set:
			issues.append("wrong set prefix '%s' (expected '%s'): %s"
				% [parts[0], expected_set, filename])
			continue
		var img := Image.new()
		if img.load(dir_path.path_join(filename)) != OK:
			issues.append("unreadable PNG: %s" % filename)
			continue
		if Vector2i(img.get_width(), img.get_height()) != frame_size:
			issues.append("wrong size %dx%d (expected %dx%d): %s"
				% [img.get_width(), img.get_height(), frame_size.x, frame_size.y, filename])
			continue
		if img.detect_alpha() == Image.ALPHA_NONE:
			issues.append("no alpha channel (background must be transparent): %s" % filename)
			continue
		var key := "%s_%s" % [parts[1], parts[2]]
		if not buckets.has(key):
			buckets[key] = []
		buckets[key].append([parts[3], img])
	var frames := {}
	for key: String in buckets:
		var entries: Array = buckets[key]
		entries.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var imgs: Array[Image] = []
		for e: Array in entries:
			imgs.append(e[1])
		frames[key] = imgs
	return {"issues": issues, "frames": frames}


## Grid-packs frames: one row per animation key (sorted). Returns
## {"image": Image, "regions": {"anim_dir": Array[Rect2i] ordered}}
func pack(frames: Dictionary, frame_size: Vector2i = FRAME_SIZE) -> Dictionary:
	var keys: Array = frames.keys()
	keys.sort()
	var max_cols := 0
	for key: String in keys:
		max_cols = maxi(max_cols, frames[key].size())
	var sheet := Image.create_empty(
		maxi(1, max_cols * frame_size.x), maxi(1, keys.size() * frame_size.y),
		false, Image.FORMAT_RGBA8)
	var regions := {}
	for row in range(keys.size()):
		var key: String = keys[row]
		var rects: Array[Rect2i] = []
		for col in range(frames[key].size()):
			var dst := Vector2i(col * frame_size.x, row * frame_size.y)
			sheet.blit_rect(frames[key][col],
				Rect2i(Vector2i.ZERO, frame_size), dst)
			rects.append(Rect2i(dst, frame_size))
		regions[key] = rects
	return {"image": sheet, "regions": regions}


## Builds the SpriteFrames .tres text referencing `sheet_res_path`.
func build_spriteframes_tres(sheet_res_path: String, regions: Dictionary) -> String:
	var keys: Array = regions.keys()
	keys.sort()
	var subs := ""
	var anims := ""
	var sub_id := 0
	var anim_entries: Array[String] = []
	for key: String in keys:
		var frame_refs: Array[String] = []
		for rect: Rect2i in regions[key]:
			sub_id += 1
			subs += "[sub_resource type=\"AtlasTexture\" id=\"atlas_%d\"]\n" % sub_id
			subs += "atlas = ExtResource(\"1_sheet\")\n"
			subs += "region = Rect2(%d, %d, %d, %d)\n\n" % [
				rect.position.x, rect.position.y, rect.size.x, rect.size.y]
			frame_refs.append(
				"{\n\"duration\": 1.0,\n\"texture\": SubResource(\"atlas_%d\")\n}" % sub_id)
		var anim: String = key.get_slice("_", 0)
		var fps: float = ANIM_FPS.get(anim, 8.0)
		anim_entries.append("{\n\"frames\": [%s],\n\"loop\": true,\n\"name\": &\"%s\",\n\"speed\": %.1f\n}"
			% [", ".join(frame_refs), key, fps])
	anims = ", ".join(anim_entries)
	var total_steps := sub_id + 2
	var out := "[gd_resource type=\"SpriteFrames\" load_steps=%d format=3]\n\n" % total_steps
	out += "[ext_resource type=\"Texture2D\" path=\"%s\" id=\"1_sheet\"]\n\n" % sheet_res_path
	out += subs
	out += "[resource]\nanimations = [%s]\n" % anims
	return out
