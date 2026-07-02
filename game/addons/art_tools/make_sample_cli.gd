extends SceneTree
## Dev utility: generates a spec-compliant placeholder frame set into
## art_incoming/<set>/ so the pipeline can be exercised without real art.
## Run: godot --headless --path game -s res://addons/art_tools/make_sample_cli.gd -- <set>

const DIRS := ["down", "left", "right", "up"]
const ANIMS := {"idle": 4, "walk": 6}
const DIR_TINTS := {
	"down": Color(0.9, 0.3, 0.3), "left": Color(0.3, 0.9, 0.3),
	"right": Color(0.3, 0.5, 0.9), "up": Color(0.9, 0.8, 0.3),
}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var set_name: String = args[0] if not args.is_empty() else "sample"
	var out_dir := ProjectSettings.globalize_path("res://").path_join("../art_incoming").path_join(set_name)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var count := 0
	for anim: String in ANIMS:
		for dir: String in DIRS:
			for i in range(ANIMS[anim]):
				var img := _make_frame(anim, dir, i, ANIMS[anim])
				img.save_png(out_dir.path_join("%s_%s_%s_%02d.png" % [set_name, anim, dir, i]))
				count += 1
	print("make_sample: wrote %d frames to %s" % [count, out_dir])
	quit(0)


func _make_frame(anim: String, dir: String, index: int, total: int) -> Image:
	var img := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	# Transparent background; a simple "body" whose bob animates per frame.
	var tint: Color = DIR_TINTS[dir]
	var bob := int(round(2.0 * sin(TAU * float(index) / float(total)))) if anim == "walk" else 0
	# body: 24 wide, 36 tall, feet on row 56 (pivot per spec)
	for y in range(20 + bob, 56):
		for x in range(20, 44):
			img.set_pixel(x, y, tint)
	# head marker to show facing
	var head := Color(1, 1, 1, 1)
	var hx := 32 + (8 if dir == "right" else -8 if dir == "left" else 0)
	var hy := 24 + (4 if dir == "down" else -2 if dir == "up" else 0) + bob
	for y in range(hy - 3, hy + 3):
		for x in range(hx - 3, hx + 3):
			img.set_pixel(clampi(x, 0, 63), clampi(y, 0, 63), head)
	return img
