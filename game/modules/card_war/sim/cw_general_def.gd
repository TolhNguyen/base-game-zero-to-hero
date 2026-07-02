class_name CwGeneralDef
extends Definition
## A general. combat_factor multiplies attack power when leading;
## loss_reduction (0..1) reduces own combat losses (e.g. Asun 0.25).

@export var display_name: String = ""
@export var general_class: StringName = &"warrior"
@export var combat_factor: float = 1.0
@export var loss_reduction: float = 0.0
