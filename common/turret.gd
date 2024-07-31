extends Node3D
class_name Turret

const SHOOT_COOLDOWN := 1.0
var shoot_cooldown_remaining := 0.0
@onready var input_pins: Array[Pin] = [$InputPin]
@onready var barrel: Node3D = $Barrel
@onready var focus_mesh: Node3D = $FocusMesh
