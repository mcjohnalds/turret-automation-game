extends Node3D
class_name Turret

const SHOOT_COOLDOWN := 1.0
var input_gate: Variant
var shooting := false
var shoot_cooldown_remaining := 0.0
@onready var label_3d: Label3D = $Label3D
