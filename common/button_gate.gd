extends Node3D
class_name ButtonGate

var output_value := false
@onready var output_pin: Pin = $OutputPin
@onready var focus_mesh: MeshInstance3D = $FocusMesh
