extends Node3D
class_name PulseTimerGate

var delay := 3.0
var duration := 5.0
var pulses: Array[float] = []
var timer := 0.0
var output_value := false
@onready var input_pins: Array[Pin] = [$InputPin]
@onready var output_pin: Pin = $OutputPin
@onready var decrease_delay_button: Node3D = $DecreaseDelayButton
@onready var increase_delay_button: Node3D = $IncreaseDelayButton
@onready var decrease_pulse_button: Node3D = $DecreasePulseButton
@onready var increase_pulse_button: Node3D = $IncreasePulseButton
@onready var pulse_timer_ui: PulseTimerUI = %PulseTimerUI
