class_name Player
extends CharacterBody3D


const _RUN_ACCELERATION := 80.0
const _RUN_SPED := 10.0
const _TERMINAL_VELOCITY := 10.0
const _JUMP_FORCE := 400.0
const _LOOK_SENSITIVITY := Vector2(0.25, 0.25)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var _gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var _pitch := $Yaw/Pitch
@onready var _yaw := $Yaw


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta : float) -> void:
	var acceleration := _acceleration()
	var friction := _friction()
	
	velocity.y = clampf(velocity.y, -_TERMINAL_VELOCITY, _TERMINAL_VELOCITY)
	velocity.x = clampf(velocity.x, -_TERMINAL_VELOCITY, _TERMINAL_VELOCITY)
	velocity.z = clampf(velocity.z, -_TERMINAL_VELOCITY, _TERMINAL_VELOCITY)
#	var horvel := Vector3(velocity.x, 0.0, velocity.z)
#	var length := horvel.length()
#	var max_x_vel := sqrt(pow(length, 2.0) - pow(velocity.z, 2.0))
#	var max_z_vel := sqrt(pow(length, 2.0) - pow(velocity.x, 2.0))
#	# sqrt(l**2 - y**2) >= x
#	var max := Vector3(max_x_vel, 0.0, max_z_vel)
#	print("%s\n%s\n" % [horvel, max])
	
	velocity = Vector3(
		move_toward(velocity.x, 0.0, friction),
		velocity.y,
		move_toward(velocity.z, 0.0, friction)
	)
	
	velocity += acceleration * delta
	
#	print(velocity)
	
	move_and_slide()


func _input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		_yaw.rotation_degrees.y -= (event.relative.x * _LOOK_SENSITIVITY.x)
		_pitch.rotation_degrees.x -= (event.relative.y * _LOOK_SENSITIVITY.y)
	
	elif event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				Stats.interaction_index += 1
			MOUSE_BUTTON_WHEEL_DOWN:
				Stats.interaction_index -= 1


func _acceleration() -> Vector3:
	var acceleration := Vector3.ZERO
	
	# Calculate gravitational acceleration
	acceleration.y -= _gravity
	acceleration.y += (_JUMP_FORCE + _gravity) * int(is_on_floor() and Input.is_action_just_pressed("jump"))
	
	# Calculate horizontal acceleration
	var input_dir = Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_backward") * int(is_on_floor())
	var direction = (_yaw.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if input_dir:
		acceleration.z += direction.z * _RUN_ACCELERATION
		acceleration.x += direction.x * _RUN_ACCELERATION
#	else:
#		var friction := 0.0
#		if is_on_floor():
#			friction = _DEFAULT_GROUND_FRICTION
#		_acceleration -= Vector3(velocity.x, 0.0, velocity.z) * friction
	
	return acceleration



func _friction() -> float:
	if is_on_floor():
		return 0.8
	return 0.0
