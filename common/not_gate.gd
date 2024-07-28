extends Node3D
class_name NotGate

var input_gate: Variant
var output_value := false
var output_gates: Array[Variant] = []
@onready var label_3d: Label3D = $Label3D
