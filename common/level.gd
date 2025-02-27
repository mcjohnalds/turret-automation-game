extends Node3D
class_name Level

const PRICES := {
	turret = 10,
	proximity_sensor = 10,
	or_gate = 1,
	and_gate = 1,
	not_gate = 1,
	pulse_timer = 1,
	button = 1,
	energy_regen = 1,
}
const _MAX_ENERGY := 10.0
const _enemy_scene := preload("res://common/enemy.tscn")
const _turret_scene := preload("res://common/turret.tscn")
const _or_gate_scene := preload("res://common/or_gate.tscn")
const _and_gate_scene := preload("res://common/and_gate.tscn")
const _not_gate_scene := preload("res://common/not_gate.tscn")
const _button_gate_scene := preload("res://common/button_gate.tscn")
const _pulse_timer_gate_scene := preload("res://common/pulse_timer_gate.tscn")
const _proximity_sensor_scene := preload("res://common/proximity_sensor.tscn")
const _player_blue_energized_material := preload(
	"res://common/player_blue_energized_material.tres"
)
const _wire_scene := preload("res://common/wire.tscn")
const _SENSOR_RADIUS := 6.0
var _energy := _MAX_ENERGY
var _create_wire_start_pin: Pin
var _create_wire: Wire
var _money := 100
var _pause_enemies := false
# A gate can be a ProximitySensor, OrGate, AndGate, PulseTimerGate, or Turret
@onready var _player: KinematicFpsController = %Player
@onready var _heart: Heart = %Heart
@onready var _fail_camera: Camera3D = %FailCamera
@onready var _energy_bar_control: Control = %EnergyBarControl
@onready var _instructions_label: Label = %InstructionsLabel
@onready var _instructions_label_format_string = _instructions_label.text


func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if _pause_enemies:
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			enemy.process_mode = Node.PROCESS_MODE_INHERIT
			if enemy.is_on_floor():
				enemy.velocity.y = 0.0
			else:
				enemy.velocity.y -= 9.8 * delta
			if not enemy.nav_agent.is_navigation_finished():
				var next := enemy.nav_agent.get_next_path_position()
				enemy.nav_agent.velocity = enemy.nav_agent.max_speed * enemy.global_position.direction_to(next)
			if enemy.global_position.distance_to(_heart.global_position) < 2.0:
				_heart.health -= delta * 4.0
	for gate in get_tree().get_nodes_in_group("gates"):
		if gate is ProximitySensor:
			gate.output_value = false
			for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
				if (
					enemy.global_position.distance_to(gate.global_position)
						<= _SENSOR_RADIUS
				):
					gate.output_value = true
		elif gate is PulseTimerGate:
			gate.timer += delta
			while not gate.pulses.is_empty() and gate.pulses[0] + gate.duration < gate.timer:
				# TODO: might want a linked list
				gate.pulses.pop_front()
			if gate.pulses.is_empty():
				gate.output_value = false
			else:
				gate.output_value = gate.timer >= gate.pulses[0]
	for gate in get_tree().get_nodes_in_group("gates"):
		_update_gate_recursive(gate)
	for gate in get_tree().get_nodes_in_group("gates"):
		match gate.get_script():
			Turret:
				_update_turret_shooting(gate, delta)
				_update_material_for_all_gate_pins(gate)
			PulseTimerGate:
				var ptg: PulseTimerGate = gate
				if _get_input_pin_value(ptg.input_pins[0]):
					ptg.pulses.push_back(ptg.timer + ptg.delay)
				ptg.pulse_timer_ui.pulse_timer_clock.delay = ptg.delay
				ptg.pulse_timer_ui.pulse_timer_clock.duration = ptg.duration
				ptg.pulse_timer_ui.pulse_timer_clock.pulses = ptg.pulses
				ptg.pulse_timer_ui.pulse_timer_clock.timer = ptg.timer
				_update_material_for_all_gate_pins(ptg)
			OrGate, AndGate, NotGate, ButtonGate, ProximitySensor:
				_update_material_for_all_gate_pins(gate)
	if _heart.health <= 0.0:
		_heart.health = 0.0
		_heart.visible = false
		_fail_camera.current = true
		process_mode = PROCESS_MODE_DISABLED
	_heart.health_bar_control.foreground.anchor_right = _heart.health / _heart.MAX_HEALTH
	_energy += delta
	_energy = clampf(_energy, 0.0, _MAX_ENERGY)
	_energy_bar_control.foreground.anchor_right = _energy / _MAX_ENERGY
	_update_using()
	_instructions_label.text = _instructions_label_format_string.format(
		PRICES.merged({
			"money": _money,
			"pause_enemies": "paused" if _pause_enemies else "unpaused"
		})
	)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var e: InputEventKey = event
		if e.keycode == KEY_Q and e.pressed:
			var collision := _player_camera_ray_cast(Util.PhysicsLayer.DEFAULT)
			if not collision:
				return
			var enemy: Enemy = _enemy_scene.instantiate()
			add_child(enemy)
			enemy.global_position = collision.position
			enemy.nav_agent.velocity_computed.connect(_on_enemy_velocity_computed.bind(enemy))
			enemy.nav_agent.target_position = _heart.global_position
		if e.keycode == KEY_E and e.pressed:
			_pause_enemies = not _pause_enemies
		if e.keycode >= KEY_1 and e.keycode <= KEY_7 and e.pressed:
			var scene: PackedScene
			var item: String
			match e.keycode:
				KEY_1:
					scene = _turret_scene
					item = "turret"
				KEY_2:
					scene = _proximity_sensor_scene
					item = "proximity_sensor"
				KEY_3:
					scene = _or_gate_scene
					item = "or_gate"
				KEY_4:
					scene = _and_gate_scene
					item = "and_gate"
				KEY_5:
					scene = _not_gate_scene
					item = "not_gate"
				KEY_6:
					scene = _pulse_timer_gate_scene
					item = "pulse_timer"
				KEY_7:
					scene = _button_gate_scene
					item = "button"
			var collision := _player_camera_ray_cast(Util.PhysicsLayer.DEFAULT)
			if not collision:
				return
			var price: int = PRICES[item]
			if price > _money:
				return
			_money -= price
			var gate: Node3D = scene.instantiate()
			var up: Vector3
			if collision.normal.cross(Vector3.UP).is_zero_approx():
				up = Vector3.MODEL_FRONT
			else:
				up = Vector3.UP
			gate.basis = Basis.looking_at(collision.normal, up, true)
			add_child(gate)
			gate.global_position = collision.position
	if event.is_action_pressed("primary"):
		var collision := _player_camera_ray_cast(
			Util.PhysicsLayer.DEFAULT | Util.PhysicsLayer.USEABLE
		)
		if _create_wire:
			if collision and collision.collider is Pin:
				_finish_creating_wire(collision.collider)
			else:
				_cancel_creating_wire()
		else:
			match collision.collider.get_script() if collision else null:
				ButtonGate:
					var button: ButtonGate = collision.collider
					button.output_value = not button.output_value
				Pin:
					_start_creating_wire(collision.collider)
				ChangeDelayButton:
					_on_change_delay_button_pressed(collision.collider)
	if event.is_action_pressed("secondary"):
		var collision := _player_camera_ray_cast(
			Util.PhysicsLayer.DEFAULT | Util.PhysicsLayer.USEABLE
		)
		if not collision:
			return
		var n: Node3D = collision.collider
		match n.get_script():
			Pin:
				_remove_pin_wires(n)
			NotGate:
				_money += PRICES.not_gate
				_queue_free_gate(n)
			OrGate:
				_money += PRICES.or_gate
				_queue_free_gate(n)
			AndGate:
				_money += PRICES.and_gate
				_queue_free_gate(n)
			ProximitySensor:
				_money += PRICES.proximity_sensor
				_queue_free_gate(n)
			ButtonGate:
				_money += PRICES.button
				_queue_free_gate(n)
			PulseTimerGate:
				_money += PRICES.pulse_timer
				_queue_free_gate(n)
			Turret:
				_money += PRICES.turret
				_queue_free_gate(n)
			ChangeDelayButton:
				_queue_free_gate(n.get_parent())


func _queue_free_gate(gate: Node3D) -> void:
	if "input_pins" in gate:
		for pin in gate.input_pins:
			_remove_pin_wires(pin)
	if "output_pin" in gate:
		_remove_pin_wires(gate.output_pin)
	gate.queue_free()


func _on_enemy_velocity_computed(safe_velocity: Vector3, enemy: Enemy) -> void:
	var safe_velocity_xz := Vector3(safe_velocity.x, 0.0, safe_velocity.z)
	var enemy_velocity_y := Vector3(0.0, enemy.velocity.y, 0.0)
	enemy.velocity = safe_velocity_xz.normalized() * safe_velocity.length() + enemy_velocity_y
	enemy.move_and_slide()


func _player_camera_ray_cast(collision_mask: int) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.new()
	var camera := _player.get_camera()
	query.collision_mask = collision_mask
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
	match gate.get_script():
		OrGate:
			gate.output_value = false
			for pin in gate.input_pins:
				if _get_input_pin_value(pin):
					gate.output_value = true
		AndGate:
			gate.output_value = true
			for pin in gate.input_pins:
				if not _get_input_pin_value(pin):
					gate.output_value = false
		NotGate:
			var input_pin: Pin = gate.input_pins[0]
			gate.output_value = not _get_input_pin_value(input_pin)
	if "output_pin" in gate:
		for pin in gate.output_pin.wires:
			_update_gate_recursive(pin.get_parent())


func _is_input_pin(pin: Pin) -> bool:
	var gate: Node3D = pin.get_parent()
	return "input_pins" in gate and gate.input_pins.has(pin)


func _remove_pin_wires(pin: Pin) -> void:
	for other_pin in pin.wires.keys():
		var wire: Wire = pin.wires[other_pin]
		wire.queue_free()
		pin.wires.erase(other_pin)
		other_pin.wires.erase(pin)


func _set_wire_end_position(wire: Wire, end: Vector3) -> void:
	wire.scale.z = wire.global_position.distance_to(end)
	var can_look_at := (
		not wire.global_position.is_equal_approx(end)
		and not wire
			.global_position
			.direction_to(end)
			.cross(Vector3.UP)
			.is_zero_approx()
	)
	if can_look_at:
		wire.look_at(end, Vector3.UP, true)


func _start_creating_wire(pin: Pin) -> void:
	_create_wire_start_pin = pin
	_create_wire = _wire_scene.instantiate()
	add_child(_create_wire)
	_create_wire.global_position = _create_wire_start_pin.global_position
	_create_wire.scale.z = 0.0
	if _is_input_pin(pin) and not pin.wires.is_empty():
		_remove_pin_wires(pin)


func _finish_creating_wire(end_pin: Pin) -> void:
	var input_pin: Pin
	if _is_input_pin(_create_wire_start_pin):
		input_pin = _create_wire_start_pin
	elif _is_input_pin(end_pin):
		input_pin = end_pin
	else:
		_cancel_creating_wire()
		return
	var output_pin: Pin
	if not _is_input_pin(_create_wire_start_pin):
		output_pin = _create_wire_start_pin
	elif not _is_input_pin(end_pin):
		output_pin = end_pin
	else:
		_cancel_creating_wire()
		return
	if input_pin == output_pin:
		_cancel_creating_wire()
		return
	# TODO: return early if user is creating a loop
	#
	# If we reach this point, wire connection is valid
	if not input_pin.wires.is_empty():
		_remove_pin_wires(input_pin)
	_set_wire_end_position(_create_wire, end_pin.global_position)
	output_pin.wires[input_pin] = _create_wire
	input_pin.wires[output_pin] = _create_wire
	_create_wire = null
	_create_wire_start_pin = null


func _cancel_creating_wire() -> void:
	_create_wire_start_pin = null
	_create_wire.queue_free()
	_create_wire = null


func _get_input_pin_value(input_pin: Pin) -> bool:
	match input_pin.wires.size():
		0:
			return false
		1:
			var output_pin: Pin = input_pin.wires.keys()[0]
			return output_pin.get_parent().output_value
		_:
			push_error("input pin has more than 1 wire")
			return false


func _update_using() -> void:
	var collision := _player_camera_ray_cast(
		Util.PhysicsLayer.DEFAULT | Util.PhysicsLayer.USEABLE
	)
	if _create_wire:
		if collision:
			if collision.collider is Pin:
				_set_wire_end_position(
					_create_wire, collision.collider.global_position
				)
			else:
				_set_wire_end_position(
					_create_wire, collision.position
				)
		else:
			_set_wire_end_position(
				_create_wire,
				_player.get_camera().global_position
					- 2.0 * _player.get_camera().global_basis.z
			)
	var focus_meshes := get_tree().get_nodes_in_group("focus_meshes")
	for focus_mesh: MeshInstance3D in focus_meshes:
		focus_mesh.visible = false
	match collision.collider.get_script() if collision else null:
		Pin:
			collision.collider.focus_mesh.visible = true
		ProximitySensor, ButtonGate, Turret, ChangeDelayButton:
			collision.collider.focus_mesh.visible = not _create_wire


func _on_change_delay_button_pressed(
	change_delay_button: ChangeDelayButton
) -> void:
	var gate: PulseTimerGate = change_delay_button.get_parent()
	match change_delay_button:
		gate.decrease_delay_button:
			gate.delay -= 1.0
		gate.increase_delay_button:
			gate.delay += 1.0
		gate.decrease_pulse_button:
			gate.duration -= 1.0
		gate.increase_pulse_button:
			gate.duration += 1.0


func _update_material_for_all_gate_pins(gate: Node3D) -> void:
	if "input_pins" in gate:
		for pin in gate.input_pins:
			var material := (
				_player_blue_energized_material if _get_input_pin_value(pin)
				else null
			)
			pin.prong_mesh.material_override = material
	if "output_pin" in gate:
		var material := (
			_player_blue_energized_material if gate.output_value
			else null
		)
		gate.output_pin.prong_mesh.material_override = material
		for input_pin in gate.output_pin.wires:
			var wire: Wire = gate.output_pin.wires[input_pin]
			wire.mesh.material_override = material


func _update_turret_shooting(turret: Turret, delta: float) -> void:
	var energized := _get_input_pin_value(turret.input_pins[0])
	for mesh: MeshInstance3D in turret.find_children("*", "MeshInstance3D"):
		if not mesh.is_in_group("energizeable_meshes"):
			continue
		mesh.material_override = (
			_player_blue_energized_material if energized else null
		)
	if not energized:
		return
	_energy -= 0.9 * delta
	if _energy <= 0.0:
		return
	var target_enemy: Enemy = null
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion():
			continue
		var enemy_distance := turret.global_position.distance_to(
			enemy.global_position
		)
		if enemy_distance > _SENSOR_RADIUS:
			continue
		if not target_enemy:
			target_enemy = enemy
			continue
		var closest_enemy_distance := turret.global_position.distance_to(
			target_enemy.global_position
		)
		if closest_enemy_distance < enemy_distance:
			target_enemy = enemy
	var target_position: Vector3
	if target_enemy:
		target_position = target_enemy.global_position + 1.3 * Vector3.UP
		turret.barrel.look_at(target_position, Vector3.UP, true)
	turret.shoot_cooldown_remaining -= delta
	if turret.shoot_cooldown_remaining > 0.0:
		return
	if not target_enemy:
		return
	# Shoot
	var tracer := Tracer.create(turret.barrel.global_position, target_position)
	tracer.speed = 50.0
	tracer.min_lifetime = 0.2
	add_child(tracer)
	target_enemy.queue_free()
	turret.shoot_cooldown_remaining = Turret.SHOOT_COOLDOWN
