extends Node3D
class_name TimerGate

var duration: float
var time_remaining: float
var running := false
var input_gate: Variant
var last_input_value := false
var output_value := false
var output_gates: Array[Variant] = []
@onready var label_3d: Label3D = $Label3D
