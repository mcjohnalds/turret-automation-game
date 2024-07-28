extends Node3D
class_name Level

signal code_edit_opened
signal code_edit_closed
const _enemy_scene := preload("res://common/enemy.tscn")
const _turret_scene := preload("res://common/turret.tscn")
const _or_gate_scene := preload("res://common/or_gate.tscn")
const _and_gate_scene := preload("res://common/and_gate.tscn")
const _not_gate_scene := preload("res://common/not_gate.tscn")
const _timer_gate_scene := preload("res://common/timer_gate.tscn")
const _proximity_sensor_scene := preload("res://common/proximity_sensor.tscn")
const _SENSOR_RADIUS = 6.0
var _turret_ghost: Turret
var _proximity_sensor_ghost: ProximitySensor
var _next_proximity_sensor_id := 1
var _next_or_gate_id := 1
var _next_and_gate_id := 1
var _next_not_gate_id := 1
var _next_timer_gate_id := 1
var _next_turret_id := 1
# A gate can be a ProximitySensor, OrGate, AndGate, TimerGate, or Turret
@onready var _player: KinematicFpsController = %Player
@onready var _heart: Node3D = %Heart
@onready var _code_edit: CodeEdit = %CodeEdit


func _ready() -> void:
	_proximity_sensor_ghost = _proximity_sensor_scene.instantiate()
	add_child(_proximity_sensor_ghost)
	var sphere: SphereMesh = _proximity_sensor_ghost.sphere.mesh
	sphere.radius = _SENSOR_RADIUS
	sphere.height = 2.0 * sphere.radius
	_proximity_sensor_ghost.label_3d.visible = false
	_turret_ghost = _turret_scene.instantiate()
	add_child(_turret_ghost)
	_turret_ghost.label_3d.visible = false


func _physics_process(delta: float) -> void:
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_on_floor():
			enemy.velocity.y = 0.0
		else:
			enemy.velocity.y -= 9.8 * get_physics_process_delta_time()
		if enemy.nav_agent.is_navigation_finished():
			continue
		var next := enemy.nav_agent.get_next_path_position()
		enemy.nav_agent.velocity = enemy.nav_agent.max_speed * enemy.global_position.direction_to(next)
	if Input.is_key_pressed(KEY_1):
		var collision := _player_camera_ray_cast()
		if collision:
			_turret_ghost.visible = true
			_turret_ghost.global_position = collision.position
		else:
			_turret_ghost.visible = false
	else:
		_turret_ghost.visible = false
	if Input.is_key_pressed(KEY_2):
		var collision := _player_camera_ray_cast()
		if collision:
			_proximity_sensor_ghost.visible = true
			_proximity_sensor_ghost.global_position = collision.position
		else:
			_proximity_sensor_ghost.visible = false
	else:
		_proximity_sensor_ghost.visible = false
	for gate in get_tree().get_nodes_in_group("gates"):
		if gate is ProximitySensor:
			gate.output_value = false
			for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
				if enemy.global_position.distance_to(gate.global_position) <= _SENSOR_RADIUS:
					gate.output_value = true
		elif gate is TimerGate:
			gate.output_value = false
			if gate.running:
				gate.time_remaining -= delta
				if gate.time_remaining <= 0.0:
					gate.time_remaining = 0.0
					gate.output_value = true
		elif gate is Turret:
			gate.shooting = false
		else:
			gate.output_value = false
	for gate in get_tree().get_nodes_in_group("gates"):
		_update_gate_recursive(gate)
	for gate in get_tree().get_nodes_in_group("gates"):
		if gate is Turret:
			if gate.input_gate and gate.input_gate.output_value:
				gate.shooting = true
			gate.label_3d.text = "%s shooting=%s" % [gate.name, gate.shooting]
		elif gate is TimerGate:
			var input_value: bool = gate.input_gate and gate.input_gate.output_value
			if not gate.last_input_value and input_value:
				gate.running = true
				gate.time_remaining = gate.duration
			gate.last_input_value = input_value
			gate.label_3d.text = "%s time_remaining=%.1f output_value=%s" % [gate.name, gate.time_remaining, gate.output_value]
		else:
			gate.label_3d.text = "%s output_value=%s" % [gate.name, gate.output_value]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var e: InputEventKey = event
		if e.keycode == KEY_Q and e.pressed:
			var collision := _player_camera_ray_cast()
			if not collision:
				return
			var enemy: Enemy = _enemy_scene.instantiate()
			add_child(enemy)
			enemy.global_position = collision.position
			enemy.nav_agent.velocity_computed.connect(_on_enemy_velocity_computed.bind(enemy))
			enemy.nav_agent.target_position = _heart.global_position
		if e.keycode == KEY_1 and not e.pressed:
			var collision := _player_camera_ray_cast()
			if not collision:
				return
			var turret: Turret = _turret_scene.instantiate()
			add_child(turret)
			turret.global_position = collision.position
			turret.name = "turret_%s" % _next_turret_id
			_next_turret_id += 1
		if e.keycode == KEY_2 and not e.pressed:
			var collision := _player_camera_ray_cast()
			if not collision:
				return
			var proximity_sensor: ProximitySensor = _proximity_sensor_scene.instantiate()
			add_child(proximity_sensor)
			proximity_sensor.sphere.visible = false
			proximity_sensor.global_position = collision.position
			proximity_sensor.name = "proximity_sensor_%s" % _next_proximity_sensor_id
			_next_proximity_sensor_id += 1
		if e.keycode == KEY_3 and not e.pressed:
			var collision := _player_camera_ray_cast()
			if not collision:
				return
			var gate: OrGate = _or_gate_scene.instantiate()
			add_child(gate)
			gate.global_position = collision.position
			gate.name = "or_%s" % _next_or_gate_id
			_next_or_gate_id += 1
		if e.keycode == KEY_4 and not e.pressed:
			var collision := _player_camera_ray_cast()
			if not collision:
				return
			var gate: AndGate = _and_gate_scene.instantiate()
			add_child(gate)
			gate.global_position = collision.position
			gate.name = "and_%s" % _next_and_gate_id
			_next_and_gate_id += 1
		if e.keycode == KEY_5 and not e.pressed:
			var collision := _player_camera_ray_cast()
			if not collision:
				return
			var gate: NotGate = _not_gate_scene.instantiate()
			add_child(gate)
			gate.global_position = collision.position
			gate.name = "not_%s" % _next_not_gate_id
			_next_not_gate_id += 1
		if e.keycode == KEY_6 and not e.pressed:
			var collision := _player_camera_ray_cast()
			if not collision:
				return
			var gate: TimerGate = _timer_gate_scene.instantiate()
			add_child(gate)
			gate.global_position = collision.position
			gate.name = "timer_%s" % _next_timer_gate_id
			_next_timer_gate_id += 1
		if e.keycode == KEY_C and e.pressed:
			_code_edit.visible = true
			_code_edit.grab_focus()
			code_edit_opened.emit()
		if e.keycode == KEY_ESCAPE and e.pressed and _code_edit.visible:
			_code_edit.visible = false
			_parse_code(_code_edit.text)
			get_viewport().set_input_as_handled()
			code_edit_closed.emit()


func _on_enemy_velocity_computed(safe_velocity: Vector3, enemy: Enemy) -> void:
	enemy.velocity = (Vector3(1.0, 0.0, 1.0) * safe_velocity).normalized() * safe_velocity.length()
	enemy.move_and_slide()


func _player_camera_ray_cast() -> Dictionary:
	var query := PhysicsRayQueryParameters3D.new()
	var camera := _player.get_camera()
	query.from = camera.global_position
	query.to = camera.global_position - camera.global_basis.z * 1000.0
	query.exclude = [_player.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)


# TODO: add max_iterations param to prevent infinite loops
#
# TODO: stop algorithm if no gate output value changed
#
# TODO: i probably only need to do this for OrGate, AndGate, NotGate
#
# TODO: i can probably do this way more efficiently without recursion by
# updating every node once in a careful order
func _update_gate_recursive(gate: Variant) -> void:
	if gate is OrGate:
		for input in gate.input_gates:
			if input.output_value:
				gate.output_value = true
	elif gate is AndGate:
		if gate.input_gates.is_empty():
			gate.output_value = false
		else:
			gate.output_value = true
			for input in gate.input_gates:
				if not input.output_value:
					gate.output_value = false
	elif gate is NotGate:
		if gate.input_gate:
			gate.output_value = not gate.input_gate.output_value
	if "output_gates" in gate:
		for g in gate.output_gates:
			_update_gate_recursive(g)


func _parse_code(code: String) -> void:
	var json := JSON.new()
	var error := json.parse(code)
	if error != OK:
		push_error("JSON parse error: ", json.get_error_message(), " at line ", json.get_error_line())
		return
	if typeof(json.data) != TYPE_ARRAY:
		push_error("Expected root type to be array")
		return
	for gate in json.data:
		if typeof(gate) != TYPE_DICTIONARY:
			push_error("Expected root array element to be dictionary")
			return
		if _expect_gate_field_type(gate, "class_name", TYPE_STRING) != OK:
			return
		if _expect_gate_field_type(gate, "name", TYPE_STRING) != OK:
			return
		match gate["class_name"]:
			"ProximitySensor":
				pass
			"TimerGate":
				if _expect_gate_field_type(gate, "duration", TYPE_FLOAT) != OK:
					return
				if _expect_gate_field_type(gate, "input_gate", TYPE_STRING) != OK:
					return
			"OrGate":
				if _expect_gate_field_input_gates(gate) != OK:
					return
			"AndGate":
				if _expect_gate_field_input_gates(gate) != OK:
					return
			"NotGate":
				if _expect_gate_field_type(gate, "input_gate", TYPE_STRING) != OK:
					return
			"Turret":
				if _expect_gate_field_type(gate, "input_gate", TYPE_STRING) != OK:
					return
			_:
				push_error("Unexpected class_name value %s", gate["class_name"])
				return
	var output_gate_names: Array[String] = []
	for node in get_tree().get_nodes_in_group("gates"):
		if node is not Turret:
			output_gate_names.append(node.name)
	for gate in json.data:
		if "input_gate" in gate and not output_gate_names.has(gate["input_gate"]):
			push_error('Gate "%s.input_gate" is "%s" but no such gate exists' % [gate.name, gate["input_gate"]])
			return
		if "input_gates" in gate:
			for input in gate["input_gates"]:
				if not output_gate_names.has(input):
					push_error('Gate "%s.input_gates" contains "%s" but not such gate exists' % [gate.name, input])
					return
	for gate in json.data:
		if not get_node_or_null(gate.name):
			push_error('Node not found with name "%s"' % gate.name)
			return
	for gate in json.data:
		var node := get_node(gate.name)
		match gate["class_name"]:
			"ProximitySensor":
				node.output_value = false
				node.output_gates = []
			"TimerGate":
				node.duration = gate["duration"]
				node.time_remaining = gate["duration"]
				node.running = false
				node.input_gate = null
				node.last_input_value = false
				node.output_value = false
				node.output_gates = []
			"OrGate":
				node.input_gates = []
				node.output_value = false
				node.output_gates = []
			"AndGate":
				node.input_gates = []
				node.output_value = false
				node.output_gates = []
			"NotGate":
				node.input_gate = null
				node.output_value = false
				node.output_gates = []
			"Turret":
				node.input_gate = null
				node.shooting = false
		if "input_gate" in gate:
			var input_node := get_node(gate["input_gate"])
			node.input_gate = input_node
			input_node.output_gates.append(node)
		if "input_gates" in gate:
			node.input_gates = []
			for input in gate["input_gates"]:
				var input_node := get_node(input)
				node.input_gates.append(input_node)
				input_node.output_gates.append(node)


func _expect_gate_field_type(gate: Dictionary, key: String, type: int) -> Error:
	if key not in gate:
		push_error("Expected gate to have %s field" % key)
		return ERR_INVALID_DATA
	if typeof(gate[key]) != type:
		push_error("Expected gate.%s to be %s" % [key, type_string(type)])
		return ERR_INVALID_DATA
	return OK


func _expect_gate_field_input_gates(gate: Dictionary) -> Error:
	if _expect_gate_field_type(gate, "input_gates", TYPE_ARRAY) != OK:
		return ERR_INVALID_DATA
	for v in gate["input_gates"]:
		if typeof(v) != TYPE_STRING:
			push_error("Expected gate.input_gates[n] to be string")
			return ERR_INVALID_DATA
	return OK
