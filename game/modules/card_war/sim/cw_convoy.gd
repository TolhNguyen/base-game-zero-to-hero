class_name CwConvoy
extends RefCounted
## A food convoy in transit. Abstracted: no escort/interception in the slice.

var id := 0
var food := 0
var pos := Vector2i.ZERO
var path: Array[Vector2i] = []
var target_kind: StringName = &"camp"  # camp | army
var target_id: Variant = null
