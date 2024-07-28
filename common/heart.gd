extends Node3D
class_name Heart

const MAX_HEALTH := 100.0
var health := MAX_HEALTH
@onready var health_bar_control: HealthBarControl = %HealthBarControl
