class_name AvianMech
extends CharacterBody3D


enum MoveStates {
	GROUND,
	AIR,
	MOVE_STATES_MAX
}

enum AIStates {
	IDLE,
	GENERIC_OBJECTIVE,
	URGENT_OBJECTIVE,
	CHASE_TARGET,
	WANDER,
	AI_STATES_MAX
}


const _GRAVITY := 20.0
const _ACCELERATION := 0.5
const _DEACCELERATION := 0.25

@export var _target_type := Constants.AvianType.AVIAN
@export_node_path("WanderPoints") var _wander_points_path : NodePath
@export var _generic_move_speed := 0.0
@export var _urgent_move_speed := 0.0
@export var _chase_move_speed := 0.0
@export var _attack_reach := 2.0
@export var _attack_amount := 50.0

var _mstate := StateMachine.new(self, MoveStates, MoveStates.GROUND, "M")
var _aistate := StateMachine.new(self, AIStates, AIStates.IDLE, "AI")

var _acceleration := Vector3.ZERO
var _move_speed := 0.0
var _target : AvianTarget
var _wander_points : PackedVector3Array

@onready var _n_agent := $NavigationAgent3D
@onready var _n_gimbal := $Gimbal
@onready var _n_eyes := $Gimbal/Eyes
@onready var _n_eyes_check := $EyesCheck
@onready var _n_idle_timer := $IdleTimer


## Private methods ##


func _ready() -> void:
	_mstate.ready()
	_aistate.ready()
	
	_wander_points = []
	if not _wander_points_path.is_empty():
		var wpn := get_node(_wander_points_path)
		if wpn is WanderPoints:
			_wander_points = wpn.get_wander_points()


func _process(delta : float) -> void:
	$DebugStateLabel.text = AIStates.keys()[_aistate.get_state()] + "\n" + MoveStates.keys()[_mstate.get_state()]
	_aistate.process(delta)
	
	if Input.is_action_pressed("interact"):
		goto_objective(get_parent().get_node("Player").position)


func _physics_process(delta : float) -> void:
	_mstate.process(delta)


func _accelerate_on_path() -> void:
	var tpos = _n_agent.get_next_path_position()
	var direction := global_position.direction_to(tpos)
	_acceleration = direction * _ACCELERATION


func _rotate_on_path() -> void:
	var tpos = _n_agent.get_next_path_position()
	var direction := global_position.direction_to(tpos)
	var dir := Vector2(direction.x, direction.z).normalized()
	_n_gimbal.rotation.y = atan2(-dir.y, dir.x)


func _target_nodes():
	return get_tree().get_nodes_in_group(Constants.AvianType.keys()[_target_type] + "_target") + get_tree().get_nodes_in_group("AVIAN_target")


func _is_target_visible(target : AvianTarget) -> bool:
	if target.is_enabled() and _n_eyes.is_position_in_frustum(target.get_global_position()):
		_n_eyes_check.set_target_position(target.get_global_position() - _n_eyes_check.get_global_position())
		await get_tree().process_frame
		
		return _n_eyes_check.get_collider() == target.get_collider()
	
	return false


## Public methods ##


func goto_objective(pos : Vector3, urgent := false) -> void:
	_n_agent.set_target_position(pos)
	if not urgent:
		_aistate.switch(AIStates.GENERIC_OBJECTIVE)
	else:
		_aistate.switch(AIStates.URGENT_OBJECTIVE)


func chase_target(target : AvianTarget) -> void:
	_target = target
	_aistate.switch(AIStates.CHASE_TARGET)


## State processes (MoveStates) ##


func _sp_M_GROUND(_delta : float) -> void:
	velocity += _acceleration
	velocity = velocity.limit_length(_move_speed)
	_n_agent.set_velocity(velocity)
	
	move_and_slide()
	
	if not is_on_floor():
		_mstate.switch(MoveStates.AIR)


func _sp_M_AIR(delta : float) -> void:
	velocity.y -= _GRAVITY * delta
	
	move_and_slide()
	
	if is_on_floor():
		_mstate.switch(MoveStates.GROUND)


## State [un]loading (MoveStates) ##


func _sl_M_GROUND() -> void:
	velocity.y = 0.0


## State processes (AIStates) ##


func _sp_AI_IDLE(_delta : float) -> void:
	_acceleration = -velocity * _DEACCELERATION
	
	for t in _target_nodes():
		if await _is_target_visible(t):
			chase_target(t)
			return
	
	if _n_idle_timer.get_time_left() == 0.0:
		_aistate.switch(AIStates.WANDER)


func _sp_AI_GENERIC_OBJECTIVE(_delta : float) -> void:
	_accelerate_on_path()
	_rotate_on_path()
	
	if _n_agent.is_navigation_finished():
		_aistate.switch(AIStates.IDLE)
		return
	
	for t in _target_nodes():
		if await _is_target_visible(t):
			chase_target(t)
			return


func _sp_AI_URGENT_OBJECTIVE(_delta : float) -> void:
	_accelerate_on_path()
	_rotate_on_path()
	
	if _n_agent.is_navigation_finished():
		_aistate.switch(AIStates.IDLE)
		return


func _sp_AI_CHASE_TARGET(_delta : float) -> void:
	if _target == null:
		_aistate.switch(AIStates.IDLE)
		return
	
	if await _is_target_visible(_target):
		_n_agent.set_target_position(_target.get_global_position())
	
	elif _n_agent.is_navigation_finished():
		_aistate.switch(AIStates.WANDER)
		return
	
	if global_position.distance_to(_target.get_global_position()) <= _attack_reach:
		_target.damage(Damage.new(Damage.DamageType.AVIAN_INDISCRIMINANT, _attack_amount))
	
	_accelerate_on_path()
	_rotate_on_path()


func _sp_AI_WANDER(_delta : float) -> void:
	for t in _target_nodes():
		if await _is_target_visible(t):
			chase_target(t)
			return
	
	if _n_agent.is_navigation_finished():
		_aistate.switch(AIStates.IDLE)
		return
	
	_accelerate_on_path()
	_rotate_on_path()


## State [un]loading (AIStates) ##

func _sl_AI_IDLE() -> void:
	_n_idle_timer.start()


func _sl_AI_GENERIC_OBJECTIVE() -> void:
	_move_speed = _generic_move_speed


func _sl_AI_URGENT_OBJECTIVE() -> void:
	_move_speed = _urgent_move_speed


func _sl_AI_CHASE_TARGET() -> void:
	_move_speed = _chase_move_speed


func _sl_AI_WANDER() -> void:
	_move_speed = _generic_move_speed
	if _wander_points:
		_n_agent.set_target_position(_wander_points[randi() % len(_wander_points)])
