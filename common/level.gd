extends Node3D
class_name Level

const _enemy_scene := preload("res://common/enemy.tscn")
@onready var _player: KinematicFpsController = %Player
@onready var _heart: Node3D = %Heart


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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var e: InputEventKey = event
		if e.keycode == KEY_Q and e.pressed:
			var query := PhysicsRayQueryParameters3D.new()
			var camera := _player.get_camera()
			query.from = camera.global_position
			query.to = camera.global_position - camera.global_basis.z * 1000.0
			query.exclude = [_player.get_rid()]
			var collision := get_world_3d().direct_space_state.intersect_ray(query)
			if not collision:
				return
			var enemy: Enemy = _enemy_scene.instantiate()
			add_child(enemy)
			enemy.global_position = collision.position
			enemy.nav_agent.velocity_computed.connect(_on_enemy_velocity_computed.bind(enemy))
			enemy.nav_agent.target_position = _heart.global_position


func _on_enemy_velocity_computed(safe_velocity: Vector3, enemy: Enemy) -> void:
	enemy.velocity = (Vector3(1.0, 0.0, 1.0) * safe_velocity).normalized() * safe_velocity.length()
	enemy.move_and_slide()
