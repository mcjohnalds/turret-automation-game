extends Node3D
class_name Level

signal code_edit_opened
signal code_edit_closed
const _enemy_scene := preload("res://common/enemy.tscn")
const _turret_scene := preload("res://common/turret.tscn")
const _proximity_sensor_scene := preload("res://common/proximity_sensor.tscn")
var _turret_ghost: Turret
var _proximity_sensor_ghost: ProximitySensor
var _next_random_word_index := 0
var _random_words: Array[String] = [
	"alpha",
	"bravo",
	"charlie",
	"delta",
	"echo",
	"foxtrot",
	"golf",
	"hotel",
	"india",
	"juliett",
	"kilo",
	"lima",
	"mike",
	"november",
	"oscar",
	"papa",
	"quebec",
	"romeo",
	"sierra",
	"tango",
	"uniform",
	"victor",
	"whiskey",
	"xray",
	"yankee",
	"zulu",
]
@onready var _player: KinematicFpsController = %Player
@onready var _heart: Node3D = %Heart
@onready var _code_edit: CodeEdit = %CodeEdit


func _ready() -> void:
	_proximity_sensor_ghost = _proximity_sensor_scene.instantiate()
	add_child(_proximity_sensor_ghost)
	var sphere: SphereMesh = _proximity_sensor_ghost.sphere.mesh
	sphere.radius = 6.0
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
	if Input.is_key_pressed(KEY_E):
		var collision := _player_camera_ray_cast()
		if collision:
			_turret_ghost.visible = true
			_turret_ghost.global_position = collision.position
		else:
			_turret_ghost.visible = false
	else:
		_turret_ghost.visible = false
	if Input.is_key_pressed(KEY_T):
		var collision := _player_camera_ray_cast()
		if collision:
			_proximity_sensor_ghost.visible = true
			_proximity_sensor_ghost.global_position = collision.position
		else:
			_proximity_sensor_ghost.visible = false
	else:
		_proximity_sensor_ghost.visible = false


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
		if e.keycode == KEY_E and not e.pressed:
			var collision := _player_camera_ray_cast()
			if not collision:
				return
			var turret: Turret = _turret_scene.instantiate()
			add_child(turret)
			turret.global_position = collision.position
			turret.label_3d.text = next_random_name()
		if e.keycode == KEY_T and not e.pressed:
			var collision := _player_camera_ray_cast()
			if not collision:
				return
			var proximity_sensor: ProximitySensor = _proximity_sensor_scene.instantiate()
			add_child(proximity_sensor)
			proximity_sensor.sphere.visible = false
			proximity_sensor.global_position = collision.position
			proximity_sensor.label_3d.text = next_random_name()
		if e.keycode == KEY_C and e.pressed:
			_code_edit.visible = true
			_code_edit.grab_focus()
			code_edit_opened.emit()
		if e.keycode == KEY_ESCAPE and e.pressed and _code_edit.visible:
			_code_edit.visible = false
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


func next_random_name() -> String:
	var word := _random_words[_next_random_word_index]
	_next_random_word_index = (_next_random_word_index + 1) % _random_words.size()
	return word
