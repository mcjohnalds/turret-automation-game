extends Node3D
class_name ProximitySensor

var output_value := false
var output_gates: Array[Variant] = []
@onready var sphere: MeshInstance3D = $Sphere
@onready var label_3d: Label3D = $Label3D
