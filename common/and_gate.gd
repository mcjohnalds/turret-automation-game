extends Node3D
class_name AndGate

var output_value := false
@onready var input_pins: Array[Pin] = [$InputPin1, $InputPin2]
@onready var output_pin: Pin = $OutputPin
