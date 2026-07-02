class_name CwOrder
extends RefCounted
## One played card, fully parameterized. params content by type:
##   march:       {general_id: StringName, troops: int, from_city: StringName, to: Vector2i}
##   gather_food: {city: StringName}
##   build_camp:  {army_id: int}
##   transport:   {from_city: StringName, food: int, target_kind: StringName, target_id: Variant}
##   assault:     {army_id: int, city: StringName}
##   feast:       {target_kind: StringName (&"army"|&"city"), target_id: Variant}

var card_id: StringName = &""
var type: StringName = &""
var params: Dictionary = {}
