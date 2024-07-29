extends Node3D
class_name ButtonGate

var output_value := false
var output_gates: Array[Variant] = []
@onready var label_3d: Label3D = $Label3D
