extends Node3D
class_name NotGate

var output_value := false
@onready var input_pins: Array[Pin] = [$InputPin]
@onready var output_pin: Pin = $OutputPin
