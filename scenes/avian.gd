class_name AvianMech
extends CharacterBody3D


enum MoveStates {
	GROUND,
	AIR
}

enum AIStates {
	IDLE,
	GENERIC_OBJECTIVE,
	URGENT_OBJECTIVE
}


const _GRAVITY := 20.0
const _ACCELERATION := 0.5
const _DEACCELERATION := 0.25

@export var _generic_move_speed := 0.0
@export var _urgent_move_speed := 0.0

var _mstate := StateMachine.new(self, MoveStates, MoveStates.GROUND, "M")
var _aistate := StateMachine.new(self, AIStates, AIStates.IDLE, "AI")

var _acceleration := Vector3.ZERO
var _move_speed := 0.0

@onready var _n_agent := $NavigationAgent3D
@onready var _n_gimbal := $Gimbal


## Private methods ##


func _ready() -> void:
	goto_objective(Vector3.ZERO)


func _process(delta : float) -> void:
	_aistate.process(delta)
	
	if Input.is_action_pressed("interact"):
		goto_objective(get_parent().get_node("Player").position)


func _physics_process(delta : float) -> void:
	_mstate.process(delta)


## Public methods ##


func goto_objective(pos : Vector3, urgent := false) -> void:
	_n_agent.set_target_position(pos)
	if not urgent:
		_aistate.switch(AIStates.GENERIC_OBJECTIVE)
	else:
		_aistate.switch(AIStates.URGENT_OBJECTIVE)


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


func _sp_AI_GENERIC_OBJECTIVE(_delta : float) -> void:
	var tpos = _n_agent.get_next_path_position()
	var direction := global_position.direction_to(tpos)
	_acceleration = direction * _ACCELERATION
	
	var dir := Vector2(direction.x, direction.z).normalized()
	_n_gimbal.rotation.y = atan2(-dir.y, dir.x)
	
	if _n_agent.is_navigation_finished():
		_aistate.switch(AIStates.IDLE)


func _sp_AI_URGENT_OBJECTIVE(delta : float) -> void:
	_sp_AI_GENERIC_OBJECTIVE(delta)


## State [un]loading (AIStates) ##


func _sl_AI_GENERIC_OBJECTIVE() -> void:
	_move_speed = _generic_move_speed


func _sl_AI_URGENT_OBJECTIVE() -> void:
	_move_speed = _urgent_move_speed
