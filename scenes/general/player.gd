class_name Player
extends CharacterBody3D

enum States {
	DEFAULT,
	GROUND,
	JUMP,
	CLIMB,
	QUICK_CLIMB,
	AIR,
	LAND,
	WALLRUN,
	DEAD,
}

#const _Ragdoll := preload("res://src/instance/RobotRagdoll.tscn")
#const _SFX := preload("res://src/instance/SoundEffect.tscn")

const _GRAVITY := 20.0
const _JUMP_FORCE := 7.0
const _WALK_SPEED := 4.0
const _RUN_SPEED := 7.0
const _AIR_FRICTION := 0.1
const _MAX_HEALTH := 100.0
const _HEAL_RATE := 20.0 # health per second
const _HOLD_HEALTH_TIME := 2000 # measured in milliseconds
const _WALLRUN_CAM_TILT := 5.0
const _WALLRUN_FALL_SPEED := -0.5
const _FAST_SPEED := 1.5
const _DAMAGE_COOLDOWN := 500
const _CAM_HEIGHT := 0.5
const _CLIMB_DISTANCE := 0.7
const _CLIMB_SPEED := 1.7
const _QUICK_CLIMB_HEIGHT := 0.6
const _QUICK_CLIMB_SPEED := 2.0
const _QUICK_CLIMB_FDIST := 2.0

var _state := StateMachine.new(self, States)
var _wallrun_cast : RayCast3D
var _health := _MAX_HEALTH
var _last_damage_time := 0
var _target_camera_tilt := 0.0
var _last_step_sound := 0

var speed_factor := 1.0

@onready var _n_gimbal := $Gimbal
@onready var _n_cam := $Gimbal/Camera3D
#@onready var _n_hacky_floor_check := $HackyFloorCheck
@onready var _n_wallrunl_check := $Gimbal/WallrunLeftCheck
@onready var _n_wallrunr_check := $Gimbal/WallrunRightCheck
@onready var _n_wallrun_tracker := $WallrunTracker
#@onready var _n_pause_menu := $Control/PauseMenu
@onready var _n_interact_cast := $Gimbal/Camera3D/InteractCast
@onready var _n_climb_check := $Gimbal/ClimbCheck
@onready var _n_climb_space_check := $Gimbal/ClimbCheck/SpaceCheck


## Private methods ##

func _ready() -> void:
	_n_cam.position.y = _CAM_HEIGHT
	_n_climb_check.position.z = -_CLIMB_DISTANCE
	_health = _MAX_HEALTH
	_state.switch(States.DEFAULT)


func _input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		if not _state.matches(States.QUICK_CLIMB):
			_n_gimbal.rotation_degrees.y -= event.relative.x * Settings.camera_sensitivity
			_n_cam.rotation_degrees.x -= event.relative.y * Settings.camera_sensitivity
			_n_cam.rotation_degrees.x = clamp(_n_cam.rotation_degrees.x, -90, 90)


func _physics_process(delta : float) -> void:
	_state.process(delta)
	_controller_look()
	_camera_tilt()


func _controller_look() -> void:
	if not _state.matches(States.CLIMB):
		var input := Vector2(
			Input.get_action_strength("look_right") - Input.get_action_strength("look_left"),
			Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
		)
		
		_n_gimbal.rotation_degrees.y -= input.x * Settings.controller_sensitivity
		_n_cam.rotation_degrees.x -= input.y * Settings.controller_sensitivity
		_n_cam.rotation_degrees.x = clamp(_n_cam.rotation_degrees.x, -90, 90)


func _camera_tilt() -> void:
	_n_cam.rotation_degrees.z = lerp(_n_cam.rotation_degrees.z, _target_camera_tilt, 0.2)


func _step_sound() -> void:
	pass


func _can_climb() -> bool:
	if not _n_climb_check.is_colliding():
		return false
	
	var dist : float = _n_climb_check.global_position.y - _n_climb_check.get_collision_point().y
	
	_n_climb_space_check.position.y = -dist
	
	await get_tree().physics_frame # must wait for collision to update
	
	if _n_climb_space_check.has_overlapping_bodies():
		return false
	
	return true


func _can_quick_climb() -> bool:
	if not _n_climb_check.is_colliding():
		return false
	
	var dist : float = _n_climb_check.global_position.y - _n_climb_check.get_collision_point().y
	
	if dist < _QUICK_CLIMB_HEIGHT:
		return false
	
	_n_climb_space_check.position.y = -dist
	
	await get_tree().physics_frame # must wait for collision to update
	
	if _n_climb_space_check.has_overlapping_bodies():
		return false
	
	return true


func _ground_movement(_delta : float) -> void:
	var input := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	
	_n_cam.v_offset = lerp(_n_cam.v_offset, sin(Time.get_ticks_msec() * 0.01) * 0.1 * int(input.x or input.y), 0.2)
	
	var theta : float = _n_gimbal.global_transform.basis.get_euler().y
	
	var move_forward := Vector3(sin(theta) * input.y, 0.0, cos(theta) * input.y)
	var move_strafe := Vector3(cos(-theta) * input.x, 0.0, sin(-theta) * input.x)
	var speed : float = _RUN_SPEED if Input.is_action_pressed("run") else _WALK_SPEED
	velocity = (move_forward + move_strafe).normalized() * speed * speed_factor * max(_FAST_SPEED, 1.0)
	
	if velocity != Vector3.ZERO and Time.get_ticks_msec() - _last_step_sound > 500:
		_last_step_sound = Time.get_ticks_msec()
		_step_sound()
	
	move_and_slide()


func _air_movement(delta : float) -> void:
	var input := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	
	var theta = _n_gimbal.global_transform.basis.get_euler().y
	
	var move_forward = Vector3(sin(theta) * input.y, 0.0, cos(theta) * input.y)
	var move_strafe = Vector3(cos(-theta) * input.x, 0.0, sin(-theta) * input.x)
	var accel := _GRAVITY * delta
	
	velocity.x = clamp(velocity.x + (move_forward.x + move_strafe.x) * _AIR_FRICTION, -_RUN_SPEED * speed_factor * max(_FAST_SPEED, 1.0), _RUN_SPEED * speed_factor * max(_FAST_SPEED, 1.0))
	velocity.z = clamp(velocity.z + (move_forward.z + move_strafe.z) * _AIR_FRICTION, -_RUN_SPEED * speed_factor * max(_FAST_SPEED, 1.0), _RUN_SPEED * speed_factor * max(_FAST_SPEED, 1.0))
	velocity.y -= accel
	
	move_and_slide()


func _permit_interact() -> void:
	if Input.is_action_pressed("interact"):
		var col = _n_interact_cast.get_collider()
		if col is InteractArea:
			col.interact(not Input.is_action_just_pressed("interact"))


## State processes ##

func _sp_GROUND(delta : float) -> void:
	_ground_movement(delta)
	_permit_interact()
	
	if Input.is_action_pressed("run"):
		if await _can_quick_climb() and is_equal_approx(velocity.length(), _RUN_SPEED * _FAST_SPEED):
			_state.switch(States.QUICK_CLIMB)
			return
	
	if Input.is_action_just_pressed("jump"):
		if await _can_climb():
			_state.switch(States.CLIMB)
			return
	
	elif Input.is_action_pressed("jump"):
		_state.switch(States.JUMP)
		return
	
	if not is_on_floor():
		_state.switch(States.AIR)
		return


func _sp_LAND(delta : float) -> void:
	_n_cam.v_offset = max(_n_cam.v_offset - 2.0 * delta, -0.2)
	_permit_interact()
	
	if _state.get_state_time() > 0.1:
		_state.switch(States.GROUND)
		return
	
	move_and_slide()
	
	if Input.is_action_pressed("jump"):
		_state.switch(States.JUMP)
		return


func _sp_AIR(delta : float) -> void:
	var impact_vel := velocity.y
	var accel := _GRAVITY * delta
	
	_air_movement(delta)
	_permit_interact()
	
	if Input.is_action_pressed("jump"):
		if await _can_climb():
			_state.switch(States.CLIMB)
			return
	
	if is_on_floor():
		_state.switch(States.LAND if impact_vel < -accel - 0.1 else States.GROUND)
		return
	
	if Input.is_action_just_pressed("jump"):
		for c in [ {
				"raycast": _n_wallrunl_check,
				"input": "move_left"
			}, {
				"raycast": _n_wallrunr_check,
				"input": "move_right"
		} ]:
			if c["raycast"].get_collider() and Input.is_action_pressed(c["input"]):
				_wallrun_cast = c["raycast"]
				_state.switch(States.WALLRUN)
				return


func _sp_WALLRUN(_delta : float) -> void:
	var normal : Vector3 = _n_wallrun_tracker.get_collision_normal()
	_n_wallrun_tracker.target_position = -Vector3(normal.x, 0.0, normal.z)
	var angle := atan2(normal.z, normal.x) + PI * 0.5 * (-1 if _wallrun_cast == _n_wallrunr_check else 1)
	
	if velocity != Vector3.ZERO and Time.get_ticks_msec() - _last_step_sound > 200:
		_last_step_sound = Time.get_ticks_msec()
		_step_sound()
	
	var forvel : Vector3 = -Vector3(cos(angle), 0.0, sin(angle)) * 10.0
	velocity = forvel
	velocity += _n_wallrun_tracker.target_position
	velocity.y = _WALLRUN_FALL_SPEED
	
	move_and_slide()
	
	_target_camera_tilt = _WALLRUN_CAM_TILT * (-1.0 if _wallrun_cast == _n_wallrunl_check else 1.0)
	
	if not _n_wallrun_tracker.get_collider():
		velocity = forvel
		_state.switch(States.JUMP)
		return
	
	if Input.is_action_just_released("jump"):
		velocity = normal * _JUMP_FORCE
		_state.switch(States.JUMP)
		return
	
	if is_on_floor():
		_state.switch(States.GROUND)
		return


func _sp_DEAD(_delta : float) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


## State [un]loading ##

func _sl_DEFAULT() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if is_on_floor():
		_state.switch(States.GROUND)
	else:
		_state.switch(States.AIR)


func _sl_WALLRUN() -> void:
	var normal := _wallrun_cast.get_collision_normal()
	_n_wallrun_tracker.target_position = -Vector3(normal.x, 0.0, normal.z)


func _su_WALLRUN() -> void:
	_target_camera_tilt = 0.0


func _sl_LAND() -> void:
	pass


func _sl_GROUND() -> void:
	pass


func _su_GROUND() -> void:
	get_tree().create_tween().tween_property(_n_cam, "v_offset", 0.0, 1)


func _sl_JUMP() -> void:
	velocity.y = _JUMP_FORCE
	_state.switch(States.AIR)


func _sl_CLIMB() -> void:
	var target_position : Vector3 = _n_climb_check.get_collision_point() + Vector3(0.0, 1.0, 0.0)
	var dist : float = _n_climb_check.global_position.y - _n_climb_check.get_collision_point().y
#	var dir := Vector3(global_position.x, 0.0, global_position.z).direction_to(Vector3(target_position.x, 0.0, target_position.z))
	
#	var target_dir := Vector2(target_position.x, target_position.z).direction_to(Vector2(global_position.x, global_position.z)).normalized()
#	var vel_dir := -Vector2(velocity.x, velocity.z).normalized()\
#
#	if not (vel_dir == Vector2.ZERO or vel_dir == target_dir):
#		_state.switch(States.DEFAULT)
#		return
	
	var climb_height : float = _n_climb_check.position.y + 1.0 - dist
	var climb_time := climb_height / _CLIMB_SPEED
	var cam_pos : Vector3 = _n_cam.position
#	var cam_rot : Vector3 = _n_cam.rotation
#	var gim_rot := atan2(-dir.z, dir.x) - 0.5 * PI
	
	var tween_bob := get_tree().create_tween().bind_node(self)
	var tween_forward := get_tree().create_tween().bind_node(self)
	var tween_tilt := get_tree().create_tween().bind_node(self)
	
	tween_bob.tween_property(_n_cam, "position:y", climb_height + _CAM_HEIGHT - 0.5, climb_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween_bob.tween_property(_n_cam, "position:y", climb_height + _CAM_HEIGHT + 0.25, 0.5 / _CLIMB_SPEED).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween_bob.tween_property(_n_cam, "position:y", climb_height + _CAM_HEIGHT, 0.5 / _CLIMB_SPEED).set_trans(Tween.TRANS_QUAD)
	
	tween_forward.tween_property(_n_cam, "global_position:x", target_position.x, 1.0 / _CLIMB_SPEED)
	tween_forward.tween_property(_n_cam, "global_position:z", target_position.z, 1.0 / _CLIMB_SPEED)
	
	tween_tilt.tween_property(_n_cam, "rotation_degrees:z", PI, 0.25 / _CLIMB_SPEED).set_delay(climb_time * 0.8)
	
	await tween_bob.finished
	
	var tween_adjust := get_tree().create_tween().bind_node(self).parallel()
	
	tween_adjust.tween_property(_n_cam, "global_position", target_position + Vector3(0.0, _CAM_HEIGHT, 0.0), 0.1)
#	tween_adjust.tween_property(_n_cam, "rotation", cam_rot, 0.1)
#	tween_adjust.tween_property(_n_gimbal, "rotation:y", gim_rot, 0.1)
	
	await tween_adjust.finished
	
	_n_cam.position = cam_pos
#	_n_cam.rotation = cam_rot
	global_position = target_position
	velocity = Vector3.ZERO
	_state.switch(States.DEFAULT)


func _sl_QUICK_CLIMB() -> void:
	var fdir := Vector3(velocity.x, 0.0, velocity.z).normalized()
	var target_position : Vector3 = _n_climb_check.get_collision_point() + Vector3(0.0, 1.0, 0.0) + fdir * _QUICK_CLIMB_FDIST
	var dist : float = _n_climb_check.global_position.y - _n_climb_check.get_collision_point().y
	
#	var target_dir := Vector2(target_position.x, target_position.z).direction_to(Vector2(global_position.x, global_position.z)).normalized()
#	var vel_dir := -Vector2(velocity.x, velocity.z).normalized()\
#
#	if not (vel_dir == Vector2.ZERO or vel_dir == target_dir):
#		_state.switch(States.DEFAULT)
#		return
	
	var climb_height : float = _n_climb_check.position.y + 1.0 - dist
	var climb_time := climb_height / _QUICK_CLIMB_SPEED
	var cam_pos : Vector3 = _n_cam.position
	var cam_rot : Vector3 = _n_cam.rotation
	
	var tween_bob := get_tree().create_tween().bind_node(self)
	var tween_forward := get_tree().create_tween().bind_node(self)
#	var tween_tilt := get_tree().create_tween().bind_node(self)
	
	tween_bob.tween_property(_n_cam, "position:y", climb_height + _CAM_HEIGHT - 0.5, climb_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween_bob.tween_property(_n_cam, "position:y", climb_height + _CAM_HEIGHT, 0.5 / _QUICK_CLIMB_SPEED).set_trans(Tween.TRANS_BOUNCE)
	
	tween_forward.tween_property(_n_cam, "position:z", -_QUICK_CLIMB_FDIST, 1.0 / _QUICK_CLIMB_SPEED).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)#.set_delay(climb_time)
	
#	tween_tilt.tween_property(_n_cam, "rotation_degrees:z", PI, 0.25 / _CLIMB_SPEED).set_delay(climb_time * 0.8)
	
	await tween_bob.finished
	
	var tween_adjust := get_tree().create_tween().bind_node(self).parallel()

	tween_adjust.tween_property(_n_cam, "global_position", target_position + Vector3(0.0, _CAM_HEIGHT, 0.0), 0.1)
	tween_adjust.tween_property(_n_cam, "rotation", cam_rot, 0.1)

	await tween_adjust.finished
	
	_n_cam.position = cam_pos
	_n_cam.rotation = cam_rot
	global_position = target_position
	_state.switch(States.DEFAULT)


func _sl_DEAD() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


## Public methods ##

func damage(damage_data : Damage) -> void:
	match _state:
		States.CLIMB:
			if damage_data.is_avian():
				return
		
		States.DEAD:
			return
	
	if Time.get_ticks_msec() - _last_damage_time > _DAMAGE_COOLDOWN:
		_last_damage_time = Time.get_ticks_msec()
		_health -= damage_data.amount


func die() -> void:
	_state.switch(States.DEAD)


func is_alive() -> bool:
	return not _state.matches(States.DEAD)
