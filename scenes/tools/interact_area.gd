class_name InteractArea
extends Area3D


signal interacted

@export var _continuous := false
@export_node_path("Logic") var _target_path

@onready var _n_target : Logic


## Private methods ##


func _ready() -> void:
	if _target_path != null:
		_n_target = get_node_or_null(_target_path)


func _handle_interaction() -> void:
	if _n_target != null:
		_n_target.activate()
	interacted.emit()


## Public methods ##


func set_target_path(path : NodePath) -> void:
	_target_path = path
	_n_target = get_node_or_null(path)


func interact(continued : bool) -> void:
	if [_continuous, continued] != [false, true]:
		_handle_interaction()
