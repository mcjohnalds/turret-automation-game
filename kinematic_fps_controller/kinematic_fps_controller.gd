extends CharacterBody3D
class_name KinematicFpsController

@export_group("Audio")
@export var material_audios: Array[MaterialAudio]
@export var water_material_audio: MaterialAudio
@export var crouch_audios: Array[AudioStream] = []
@export var uncrouch_audios: Array[AudioStream] = []
@export_group("FOV")
## Speed at which the FOV changes
@export var fov_change_speed := 20.0
## FOV to be multiplied when active the crouch
@export var crouch_fov_multiplier := 0.99
## FOV multiplier applied at max speed
@export var max_speed_fov_multiplier := 1.01
@export_group("Head Bob")
## Difference of step bob movement between vertical and horizontal angle
@export var vertical_horizontal_ratio = 2.0
@export var head_bob_x_curve : Curve
@export var head_bob_y_curve : Curve
@export_group("Quake Camera Tilt")
## Speed at which the camera angle moves
@export var quake_camera_tilt_speed := 6.0
## Rotation angle limit per move
@export var quake_camera_tilt_angle_limit := 0.004
@export_group("Movement")
## Controller Gravity Multiplier
## The higher the number, the faster the controller will fall to the ground and 
## your jump will be shorter.
@export var gravity_multiplier := 1.5
## Controller base speed
## Note: this speed is used as a basis for abilities to multiply their 
## respective values, changing it will have consequences on [b]all
## abilities[/b] that use velocity.
@export var base_speed := 3.0
@export var back_speed := 0.6
@export_group("Walk")
## Time for the character to reach full speed
@export var walk_acceleration := 5.0
## Time for the character to stop walking
@export var walk_deceleration := 9.0
## Sets control in the air
@export var air_control := 0.2
@export_group("Sprint")
## Speed to be multiplied when active the ability
@export var sprint_speed_multiplier := 2.0
@export var sprint_seconds := 30000.0
@export var sprint_regen_time := 6.0
@export var sprint_energy_jump_cost := 0.0
@export_group("Footsteps")
## Value to be added to compute a step, each frame that the character is
## walking this value is added to a counter
@export var step_interval := 4.0
## Value between 0 and 1 that determines when in a step cycle a step sound
## should play
@export var step_threshold := 0.5
@export_group("Crouch")
## Collider height when crouch actived
@export var height_in_crouch := 1.0
## Speed multiplier when crouch is actived
@export var crouch_speed_multiplier := 0.7
@export_group("Jump")
## Jump/Impulse height
@export var jump_height := 3.5
@export_group("Fly")
## Speed multiplier when fly mode is actived
@export var fly_mode_speed_modifier := 2.0
@export_group("Swim")
## Minimum height for [CharacterController3D] to be completely submerged in
## water.
@export var submerged_height := 0.36
@export var depth_on_water := 2.1
## Minimum height for [CharacterController3D] to be float in water.
@export var floating_height := 0.75
## Speed multiplier when floating water
@export var on_water_speed_multiplier := 0.75
## Speed multiplier when submerged water
@export var submerged_speed_multiplier := 0.5
@export var underwater_env: Environment
@export_group("Camera")
## Mouse Sensitivity
@export var mouse_sensitivity := 8.0
## Maximum vertical angle the head can aim
@export var vertical_angle_limit := TAU * 0.24
@export var camera_linear_pid_kp := 100.0
@export var camera_linear_pid_kd := 10.0
@export var camera_angular_pid_kp := 100.0
@export var camera_angular_pid_kd := 10.0
@export_group("Shooting")
@export var muzzle_flash_alpha_curve: Curve
@export var muzzle_flash_lifetime := 0.05
@export var smoke_lifetime := 0.3
@export var tracer_scene: PackedScene
@export var max_bullet_range := 1000.0
@export var fire_rate := 10.0
@export var weapon_linear_pid_kp := 500.0
@export var weapon_linear_pid_kd := 50.0
@export var weapon_angular_pid_kp := 300.0
@export var weapon_angular_pid_kd := 20.0
@export var bullet_impact_scene: PackedScene
@export var enable_shooting := true
@export_group("Health")
@export var max_health := 100.0
@export var blood_vignette_change_speed := 3.0
var _sprint_energy := 1.0
var _last_sprint_cooldown_at := -1000.0
var _is_flying := false
var _last_is_on_water := false
var _last_is_floating := false
var _last_is_submerged := false
var _last_is_on_floor := false
var _weapon_last_rotation := Vector3.ZERO
var _head_bob_cycle_position := Vector2.ZERO
var _quake_camera_tilt_ratio := 0.0
var _camera_linear_velocity := Vector3.ZERO
var _camera_angular_velocity := Vector3.ZERO
var _weapon_linear_velocity := Vector3.ZERO
var _weapon_angular_velocity := Vector3.ZERO
var _last_camera_position := Vector3.ZERO
var _last_camera_rotation := Vector3.ZERO
# We need to track shoot button down state instead of just relying on
# Input.is_action_pressed("shoot") so the gun doesn't shoot when the player
# clicks the unpause button.
var _shoot_button_down := false
var _gun_last_fired_at := -1000.0
var _blood_flash_alpha_target := 0.0
@onready var _head: Node3D = $Head
@onready var _camera: Camera3D =  $Head/Camera3D
@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _capsule: CapsuleShape3D = _collision.shape
@onready var _head_ray_cast: RayCast3D = $HeadRayCast
@onready var _step_audio_stream_player: AudioStreamPlayer3D = (
	$StepAudioStreamPlayer
)
@onready var _land_audio_stream_player: AudioStreamPlayer3D = (
	$LandAudioStreamPlayer
)
@onready var _jump_audio_stream_player: AudioStreamPlayer3D = (
	$JumpAudioStreamPlayer
)
@onready var _crouch_audio_stream_player: AudioStreamPlayer3D = (
	$CrouchAudioStreamPlayer
)
@onready var _uncrouch_audio_stream_player: AudioStreamPlayer3D = (
	$UncrouchAudioStreamPlayer
)
@onready var _ground_ray_cast: RayCast3D = $GroundRayCast
@onready var _swim_ray_cast: RayCast3D = $SwimRayCast
@onready var _weapon: Node3D = %Weapon
@onready var _smoke: GPUParticles3D = %Smoke
@onready var _muzzle_flashes: Array[MeshInstance3D] = [
	%MuzzleFlash1, %MuzzleFlash2, %MuzzleFlash3
]
@onready var _bullet_start: Node3D = %BulletStart
@onready var _blood_vignette: BloodVignette = %BloodVignette
@onready var _blood_flash: TextureRect = %BloodFlash
@onready var _initial_fov := _camera.fov
@onready var _initial_capsule_height = _capsule.height
@onready var _initial_weapon_position := _weapon.position
@onready var _weapon_last_position := _weapon.position
@onready var _health := max_health


func _ready() -> void:
	_smoke.emitting = false
	_update_muzzle_flash()


func _physics_process(delta: float) -> void:
	if not Input.is_action_pressed("shoot"):
		_shoot_button_down = false
	var input_horizontal := Vector2.ZERO
	var input_vertical := 0.0
	var input_crouch := false
	var input_sprint := false
	var input_jump := false
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if Input.is_action_just_pressed("move_fly_mode"):
			_is_flying = not _is_flying
		input_horizontal = Input.get_vector(
			"move_left", "move_right", "move_backward", "move_forward"
		)
		input_vertical = Input.get_axis("move_crouch", "move_jump")
		input_crouch = Input.is_action_pressed("move_crouch")
		input_sprint = Input.is_action_pressed("move_sprint")
		input_jump = Input.is_action_just_pressed("move_jump")
	var is_on_water = _swim_ray_cast.is_colliding()
	if is_on_water:
		var point := _swim_ray_cast.get_collision_point()
		depth_on_water = -_swim_ray_cast.to_local(point).y
	var is_submerged := (
		depth_on_water < submerged_height and is_on_water and !_is_flying
	)
	var is_floating := (
		depth_on_water < floating_height and is_on_water and !_is_flying
	)
	var is_entered_water := is_on_water and not _last_is_on_water
	var is_exited_water := not is_on_water and _last_is_on_water
	var landed_on_floor_this_frame := (
		not is_floating and is_on_floor() and not _last_is_on_floor
	)
	if is_floating and !_last_is_floating:
		# TODO: play started floating sound
		pass
	elif !is_floating and _last_is_floating:
		# TODO: play stopped floating sound
		pass
	if is_submerged and not _last_is_submerged:
		_camera.environment = underwater_env
	if not is_submerged and _last_is_submerged:
		_camera.environment = null
	var is_walking := not _is_flying and not is_floating
	var is_crouching := (
		input_crouch
		and is_on_floor()
		and not is_floating
		and not is_submerged
		and not _is_flying
	)
	var is_sprinting := (
		input_sprint
		and is_on_floor()
		and  input_horizontal.y >= 0.5
		and !is_crouching
		and not _is_flying
		and not is_floating
		and not is_submerged
		and _sprint_energy > 0.0
	)
	var input_direction := _get_input_direction(
		input_horizontal, input_vertical
	)
	var is_jumping := (
		input_jump
		and is_on_floor()
		and not _head_ray_cast.is_colliding()
		and _sprint_energy >= sprint_energy_jump_cost
	)
	var is_shuffling_feet := absf(_get_horizontal_velocity().length()) < 0.1
	var is_stepping := (
		not _is_flying
		and not is_floating
		and not is_submerged
		and not is_shuffling_feet
	)
	_update_quake_camera_tilt(input_horizontal, delta)
	if landed_on_floor_this_frame or is_entered_water:
		_play_land_audio(landed_on_floor_this_frame, is_on_water)
	elif is_exited_water:
		_play_jump_audio(landed_on_floor_this_frame, is_on_water)
	_update_head_bob_cycle_position(
		is_stepping, landed_on_floor_this_frame, is_on_water, delta
	)
	_update_crouch_height(is_crouching, delta)
	var is_sprint_regen_cooldown := (
		Util.get_ticks_sec() - _last_sprint_cooldown_at < 0.1
	)
	if is_sprinting:
		_sprint_energy -= delta / sprint_seconds
	elif not is_sprint_regen_cooldown:
		_sprint_energy += delta / sprint_regen_time
	_sprint_energy = clampf(_sprint_energy, 0.0, 1.0)
	if _sprint_energy <= 0.0 and input_sprint:
		_last_sprint_cooldown_at = Util.get_ticks_sec()
	_apply_gravity(is_jumping, is_submerged, delta)
	_walk(
		is_walking,
		is_crouching,
		is_sprinting,
		is_submerged,
		is_floating,
		input_direction,
		delta
	)
	_update_camera_fov(is_crouching, delta)
	if is_jumping:
		_jump(landed_on_floor_this_frame, is_on_water)
	_update_weapon_linear_velocity(delta)
	_update_weapon_angular_velocity(delta)
	_update_camera_linear_velocity(delta)
	_update_camera_angular_velocity(delta)
	_update_gun_shooting(delta)
	_update_muzzle_flash()
	_update_blood_effects(delta)
	_last_is_on_water = is_on_water
	_last_is_floating = is_floating
	_last_is_submerged = is_submerged
	_last_is_on_floor = is_on_floor()
	# No idea why but self sometimes gets scaled a little bit and we have to
	# reset it or else move_and_slide will error
	scale = Vector3.ONE
	move_and_slide()


func _input(event: InputEvent) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	if event.is_action_pressed("shoot"):
		_shoot_button_down = true
	if event.is_action_released("shoot"):
		_shoot_button_down = false
	if event.is_action_pressed("move_crouch"):
		_crouch_audio_stream_player.stream = crouch_audios.pick_random()
		_crouch_audio_stream_player.play()
	if event.is_action_released("move_crouch"):
		_uncrouch_audio_stream_player.stream = uncrouch_audios.pick_random()
		_uncrouch_audio_stream_player.play()
	if event is InputEventMouseMotion:
		var e: InputEventMouseMotion = event
		var s: float = mouse_sensitivity / 1000.0 * global.mouse_sensitivity
		var i := -1.0 if global.invert_mouse else 1.0
		var last_x := _head.rotation.x
		var last_y := rotation.y
		rotation.y -= e.relative.x * s
		_head.rotation.x = clamp(
			_head.rotation.x - e.relative.y * s * i,
			-vertical_angle_limit,
			vertical_angle_limit
		)
		var dx := angle_difference(_head.rotation.x, last_x)
		var dy := angle_difference(rotation.y, last_y)
		_weapon_linear_velocity += Vector3(-dy, dx, 0.0)
		_weapon_angular_velocity += Vector3(dx, dy, 0.0)
	if event is InputEventKey and OS.is_debug_build():
		var e: InputEventKey = event
		if e.keycode == KEY_L and e.pressed:
			_damage(10.0)


func _update_quake_camera_tilt(input_horizontal: Vector2, delta: float) -> void:
	var target := input_horizontal.x
	var direction := signf(target - _quake_camera_tilt_ratio)
	var new_ratio := (
		_quake_camera_tilt_ratio + quake_camera_tilt_speed * direction * delta
	)
	var new_direction := signf(target - new_ratio)
	if new_direction != direction:
		_quake_camera_tilt_ratio = target
	else:
		_quake_camera_tilt_ratio = new_ratio
	_camera.rotation.z = lerp(
		-quake_camera_tilt_angle_limit,
		quake_camera_tilt_angle_limit,
		smoothstep(-1.0, 1.0, -_quake_camera_tilt_ratio)
	)


func _update_crouch_height(is_crouching: bool, delta: float) -> void:
	var h := _capsule.height
	if is_crouching:
		h -= delta * 8.0
	elif not _head_ray_cast.is_colliding():
		h += delta * 8.0
	var previous_capsule_height := _capsule.height
	_capsule.height = clampf(h, height_in_crouch, _initial_capsule_height)
	var dh := (_capsule.height - previous_capsule_height) * delta
	_weapon_linear_velocity += Vector3(0.0, dh * 100.0, 0.0)
	_weapon_angular_velocity += Vector3(dh * delta * 500.0, 0.0, 0.0)


func _get_input_direction(
	input_horizontal: Vector2, input_vertical: float
) -> Vector3:
	var allow_vertical := _is_flying
	var aim := _head if allow_vertical else self
	var input_direction := Vector3.ZERO
	if input_horizontal.y >= 0.5:
		input_direction -= aim.global_basis.z
	if input_horizontal.y <= -0.5:
		input_direction += aim.global_basis.z
	if input_horizontal.x <= -0.5:
		input_direction -= aim.global_basis.x
	if input_horizontal.x >= 0.5:
		input_direction += aim.global_basis.x
	if allow_vertical:
		input_direction.y += input_vertical
	return input_direction.normalized()


func _get_material_audio_for_object(object: Object) -> MaterialAudio:
	if object.get("physics_material_override") is PhysicsMaterial:
		var material: PhysicsMaterial = object.physics_material_override
		for m in material_audios:
			if m.physics_material == material:
				return m
	return null


func _get_current_material_audio(
	landed_on_floor_this_frame: bool, is_on_water: bool
) -> MaterialAudio:
	if is_on_water:
		return water_material_audio
	if landed_on_floor_this_frame:
		var k_col = get_last_slide_collision()
		return _get_material_audio_for_object(k_col.get_collider(0))
	if _ground_ray_cast.get_collider():
		return _get_material_audio_for_object(_ground_ray_cast.get_collider())
	return null


func _play_jump_audio(
	landed_on_floor_this_frame: bool, is_on_water: bool
) -> void:
	var material_audio: MaterialAudio = _get_current_material_audio(
		landed_on_floor_this_frame, is_on_water
	)
	if not material_audio:
		return
	_jump_audio_stream_player.stream = material_audio.jump_audio_stream
	_jump_audio_stream_player.play()


func _play_land_audio(
	landed_on_floor_this_frame: bool, is_on_water: bool
) -> void:
	var material_audio: MaterialAudio = _get_current_material_audio(
		landed_on_floor_this_frame, is_on_water
	)
	if not material_audio:
		return
	_land_audio_stream_player.stream = material_audio.landed_audio_stream
	_land_audio_stream_player.play()


func _play_step_audio(
	landed_on_floor_this_frame: bool, is_on_water: bool
) -> void:
	var material_audio: MaterialAudio = _get_current_material_audio(
		landed_on_floor_this_frame, is_on_water
	)
	if not material_audio:
		return
	_step_audio_stream_player.stream = (
		material_audio.step_audio_streams.pick_random()
	)
	_step_audio_stream_player.play()


func _update_camera_fov(
	is_crouching: bool, delta: float
) -> void:
	var max_locomotion_speed := (
		base_speed * maxf(sprint_speed_multiplier, fly_mode_speed_modifier)
	)
	var a := velocity.length() / max_locomotion_speed
	var b := max_speed_fov_multiplier - 1.0
	var target_fov := _initial_fov * (1.0 + a * b)
	if is_crouching:
		target_fov *= crouch_fov_multiplier
	_camera.fov =  lerp(_camera.fov, target_fov, delta * fov_change_speed)


func _apply_gravity(
	is_jumping: bool, is_submerged: bool, delta: float
) -> void:
	var is_gravity_applied := (
		not is_jumping
		and not _is_flying
		and not is_submerged
	)
	if is_gravity_applied:
		velocity.y -= Util.get_default_gravity() * gravity_multiplier * delta


func _walk(
	is_walking: bool,
	is_crouching: bool,
	is_sprinting: bool,
	is_submerged: bool,
	is_floating: bool,
	input_direction: Vector3,
	delta: float
) -> void:
	var speed_multiplier := 1.0
	if is_crouching:
		speed_multiplier *= crouch_speed_multiplier
	if is_sprinting:
		speed_multiplier *= sprint_speed_multiplier
	if _is_flying:
		speed_multiplier *= fly_mode_speed_modifier
	if is_submerged:
		speed_multiplier *= submerged_speed_multiplier
	elif is_floating:
		speed_multiplier *= on_water_speed_multiplier
	var move_speed := base_speed * speed_multiplier
	if is_walking:
		var hv := _get_horizontal_velocity()
		var is_accelerating := input_direction.dot(hv) > 0.0
		var is_backward := input_direction.dot(global_basis.z) > 0.1
		var back_penalty := (
			back_speed if is_accelerating and  is_backward else 1.0
		)
		var a := walk_acceleration if is_accelerating else walk_deceleration
		if not is_on_floor():
			a *= air_control
		a *= back_penalty
		var target := input_direction * move_speed * back_penalty
		var w := hv.lerp(target, a * delta)
		velocity.x = w.x
		velocity.z = w.z
	if is_floating:
		var depth := floating_height - depth_on_water
		velocity = input_direction * move_speed
		if depth < 0.1:
			# Prevent free sea movement from exceeding the water surface
			velocity.y = minf(velocity.y, 0.0)
	if _is_flying:
		velocity = input_direction * move_speed


func _update_weapon_linear_velocity(delta: float) -> void:
	var error := _initial_weapon_position - _weapon.position
	var error_delta := (_weapon_last_position - _weapon.position) / delta
	var accel := (
		weapon_linear_pid_kp * error + weapon_linear_pid_kd * error_delta
	)
	_weapon_linear_velocity += accel * delta
	_weapon_linear_velocity = _weapon_linear_velocity.limit_length(7.0)
	_weapon_last_position = _weapon.position
	_weapon.position += _weapon_linear_velocity * delta
	_weapon.position = (
		_initial_weapon_position
		+ (_weapon.position - _initial_weapon_position).limit_length(1.0)
	)


func _update_weapon_angular_velocity(delta: float) -> void:
	var error := -_weapon.rotation
	var error_delta := (_weapon_last_rotation - _weapon.rotation) / delta
	var accel := (
		weapon_angular_pid_kp * error + weapon_angular_pid_kd * error_delta
	)
	_weapon_angular_velocity += accel * delta
	_weapon_angular_velocity = _weapon_angular_velocity
	_weapon_last_rotation = _weapon.rotation
	_weapon.rotation += _weapon_angular_velocity * delta


func _update_camera_linear_velocity(delta: float) -> void:
	var error := -_camera.position
	var error_delta := (_last_camera_position - _camera.position) / delta
	var accel := (
		camera_linear_pid_kp * error + camera_linear_pid_kd * error_delta
	)
	_camera_linear_velocity += accel * delta
	_last_camera_position = _camera.position
	_camera.position += _camera_linear_velocity * delta
	_camera.position = _camera.position.limit_length(0.3)


func _update_camera_angular_velocity(delta: float) -> void:
	var error := -_camera.rotation
	var error_delta := (_last_camera_rotation - _camera.rotation) / delta
	var accel := (
		camera_angular_pid_kp * error + camera_angular_pid_kd * error_delta
	)
	_camera_angular_velocity += accel * delta
	_last_camera_rotation = _camera.rotation
	_camera.rotation += _camera_angular_velocity * delta


func _update_blood_effects(delta: float) -> void:
	_blood_vignette.strength = lerpf(
		_blood_vignette.strength,
		1.0 - _health / max_health,
		delta * blood_vignette_change_speed
	)
	_blood_flash.modulate.a = lerpf(
		_blood_flash.modulate.a, _blood_flash_alpha_target, 50.0 * delta
	)
	_blood_flash_alpha_target = lerpf(
		_blood_flash_alpha_target, 0.0, 6.0 * delta
	)


func _update_gun_shooting(delta: float) -> void:
	var fire_bullet := (
		_shoot_button_down
		and Util.get_ticks_sec() - _gun_last_fired_at > 1.0 / fire_rate
	)
	if fire_bullet:
		_gun_last_fired_at = Util.get_ticks_sec()
		var query := PhysicsRayQueryParameters3D.new()
		query.from = _camera.global_position
		query.to = (
			_camera.global_position
			+ _bullet_start.global_basis.z * max_bullet_range
		)
		query.exclude = [get_rid()]
		var collision: Dictionary = (
			get_world_3d().direct_space_state.intersect_ray(query)
		)
		var bullet_end: Vector3
		if collision:
			bullet_end = collision.position
		else:
			bullet_end = query.to
		var tracer: Tracer = tracer_scene.instantiate()
		tracer.start = _bullet_start.global_position + velocity * delta
		tracer.end = bullet_end
		get_parent().add_child(tracer)
		var dlv := Vector3(
			randf_range(-0.1, 0.1),
			randf_range(0.5, 0.6),
			randf_range(0.8, 0.9)
		)
		var dav := Vector3(
			randf_range(-0.1, 3.0),
			randf_range(-3.0, 3.0),
			randf_range(-0.9, 0.9)
		)
		_weapon_linear_velocity += dlv * 0.5
		_weapon_angular_velocity += dav * 0.5
		_camera_linear_velocity += dlv * 1.0 * Vector3(1.0, 1.0, 1.2)
		_camera_angular_velocity += dav * 0.05
		if collision:
			var impact: GPUParticles3D = bullet_impact_scene.instantiate()
			impact.position = collision.position
			impact.one_shot = true
			impact.emitting = true
			get_parent().add_child(impact)
	_smoke.emitting = (
		Util.get_ticks_sec() - _gun_last_fired_at < smoke_lifetime
	)


func _update_muzzle_flash() -> void:
	for muzzle_flash in _muzzle_flashes:
		var material: StandardMaterial3D = muzzle_flash.material_override
		var t := Util.get_ticks_sec()
		var d := t - _gun_last_fired_at
		material.albedo_color.a = (
			muzzle_flash_alpha_curve.sample_baked(d / muzzle_flash_lifetime)
		)


func _jump(landed_on_floor_this_frame: bool, is_on_water: bool) -> void:
	velocity.y = jump_height
	_play_jump_audio(landed_on_floor_this_frame, is_on_water)
	_sprint_energy -= sprint_energy_jump_cost
	_head_bob_cycle_position = Vector2.ZERO


func _get_horizontal_velocity() -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)


func _update_head_bob_cycle_position(
	is_stepping: bool,
	landed_on_floor_this_frame: bool,
	is_on_water: bool,
	delta: float
) -> void:
	var hv := _get_horizontal_velocity()
	var tick_speed = hv.length() * delta / step_interval
	if is_stepping:
		var last_head_bob_cycle_position_y := _head_bob_cycle_position.y
		_head_bob_cycle_position.x += tick_speed
		_head_bob_cycle_position.y += tick_speed * vertical_horizontal_ratio
		if _head_bob_cycle_position.x > 1.0:
			_head_bob_cycle_position.x -= 1.0
		if _head_bob_cycle_position.y > 1.0:
			_head_bob_cycle_position.y -= 1.0
		if (
			last_head_bob_cycle_position_y < step_threshold
			and _head_bob_cycle_position.y >= step_threshold
		):
			_play_step_audio(landed_on_floor_this_frame, is_on_water)
		var a := _get_horizontal_velocity().length() * delta
		var x := a * Util.sample_curve_tangent(
			head_bob_x_curve, _head_bob_cycle_position.x
		)
		var y := a * Util.sample_curve_tangent(
			head_bob_x_curve, _head_bob_cycle_position.y
		)
		_camera_linear_velocity += Vector3(0.2 * x, 0.8 * y, 0.0)
		_weapon_angular_velocity += Vector3(-1.5 * y, -2.0 * x, 0.0)
	else:
		_head_bob_cycle_position.x -= maxf(
			tick_speed, 0.0
		)
		_head_bob_cycle_position.y -= maxf(
			tick_speed * vertical_horizontal_ratio, 0.0
		)


func _damage(amount: float) -> void:
	_health -= amount
	_health = maxf(_health, 0.0)
	var r := Vector3(
		randf_range(-0.5, 0.5),
		randf_range(0.5, 1.0),
		randf_range(1.0, 5.0)
	)
	_camera_linear_velocity += r
	_camera_angular_velocity += Vector3(r.y * 0.3, r.x, 0.0)
	_weapon_linear_velocity += r * 0.2
	_weapon_angular_velocity += Vector3(r.y, r.x, randf_range(-3.0, 3.0))
	_blood_flash_alpha_target = 0.3


func get_sprint_energy() -> float:
	return _sprint_energy


func get_camera() -> Camera3D:
	return _camera
