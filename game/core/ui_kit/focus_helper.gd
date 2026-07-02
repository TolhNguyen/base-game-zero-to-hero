class_name FocusHelper
extends RefCounted
## Controller-navigation helpers. UI screens must always have a focused
## control so gamepad/keyboard users can navigate without a mouse.


## Focuses and returns the first focusable visible control under `root`
## (depth-first), or null if none exists.
static func grab_first(root: Node) -> Control:
	var target := _find_focusable(root)
	if target:
		target.grab_focus()
	return target


static func _find_focusable(node: Node) -> Control:
	if node is Control \
			and (node as Control).focus_mode == Control.FOCUS_ALL \
			and (node as Control).is_visible_in_tree():
		return node
	for child in node.get_children():
		var found := _find_focusable(child)
		if found:
			return found
	return null
