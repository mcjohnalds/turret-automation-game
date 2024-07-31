extends Node3D
class_name ProximitySensor

var output_value := false
@onready var output_pin: Pin = $OutputPin
@onready var focus_mesh: Node3D = $FocusMesh
