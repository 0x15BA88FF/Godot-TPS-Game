extends KinematicBody

export(float, 0.0, 1) var health : float = 1.0
export var run_speed : float = 20.0
export var walk_speed : float = 10.0
export(float, EASE) var acceleration : float = 10
export(float, EASE) var angular_velocity : float = 20
export var mass : float = 5.0
export(int, 0, 45) var max_slope_angle : int = 45
export var jump_height : float = 15
export var max_jumps_count : int = 1
export(float, 0.0, 1) var air_control : float = 0.8
export(float, 0.1, 1) var mouse_sensitivity := 0.05
export(float, -90, 0) var min_pitch : float = -90
export(float, 0, 90) var max_pitch : float = 60

onready var _springArm : SpringArm = $SpringArm
onready var _model : Spatial = $Model
onready var _playerAnim : AnimationPlayer = $Model/Vanguard/AnimationPlayer

const GRAVITY = 9.8
var speed : float = walk_speed
var weight : float = mass * GRAVITY
var velocity : Vector3 = Vector3.ZERO
var snap_vector : Vector3 = Vector3.DOWN
var move_direction : Vector3 = Vector3.ZERO
var look_direction : Vector2 = Vector2.ZERO
var jump_count : int = 0

func animate():
	if velocity.length() < 5 and is_on_floor():
		_playerAnim.play("Idle")
	elif speed >= run_speed and is_on_floor():
		_playerAnim.play("Run")
	elif speed < run_speed and is_on_floor():
		_playerAnim.play("Walk")
	elif not is_on_floor():
		_playerAnim.play("Jump_air")

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_springArm.set_as_toplevel(true)
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_springArm.rotation_degrees.x -= event.relative.y * mouse_sensitivity
		_springArm.rotation_degrees.x = clamp(_springArm.rotation_degrees.x, min_pitch, max_pitch)
		_springArm.rotation_degrees.y -= event.relative.x * mouse_sensitivity
		
func _physics_process(delta: float) -> void:
	var just_landed : bool = is_on_floor() and snap_vector == Vector3.ZERO
	var temp_y = velocity.y
	
	# movement
	move_direction.x = Input.get_action_strength("moveRight") - Input.get_action_strength("moveLeft")
	move_direction.z = Input.get_action_strength("moveBack") - Input.get_action_strength("moveFoward")
	move_direction = move_direction.rotated(Vector3.UP, _springArm.rotation.y).normalized()

	velocity = velocity.linear_interpolate(move_direction.normalized() * speed, acceleration * delta)
	velocity.y = temp_y
	velocity = move_and_slide_with_snap(velocity, snap_vector, Vector3.UP, true, 4, deg2rad(max_slope_angle))
	
	# gravity if in air
	if not is_on_floor():
		velocity.y -= weight * delta

	# Sprint / Running
	if Input.is_action_pressed("sprint"):
		speed = run_speed
	else:
		speed = walk_speed
	
	# jumping
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or jump_count < max_jumps_count and jump_count > 0:
			velocity.y = jump_height
			snap_vector = Vector3.ZERO
			jump_count += 1
		else:
			jump_count = 0
	elif just_landed:
		snap_vector = Vector3.DOWN

	# Look at
	if velocity.length() > 5.0:
		look_direction = Vector2(velocity.z, velocity.x)
		_model.rotation.y = lerp_angle(_model.rotation.y, look_direction.angle(), angular_velocity * delta)
	
	animate()

func _process(_delta: float) -> void:
	# var spring_length : float = 0.0
	var aim_spring_length : float = 2
	var normal_spring_length : float = 5
	
	if Input.is_action_pressed("aim"):
		_springArm.spring_length = aim_spring_length
		_springArm.translation = Vector3(translation.x - 1, translation.y + 3, translation.z)
	else:
		_springArm.spring_length = normal_spring_length
		_springArm.translation = Vector3(translation.x, translation.y + 3, translation.z)

	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
