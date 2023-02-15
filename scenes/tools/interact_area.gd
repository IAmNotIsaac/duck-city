class_name InteractArea
extends Area3D


@export var _continuous := false
@export_node_path("Trigger") var _target_path

@onready var _target : Trigger = get_node(_target_path)


## Private methods ##


func _handle_interaction() -> void:
	_target.activate()


## Public methods ##


func interact(continued : bool) -> void:
	if [_continuous, continued] != [false, true]:
		_handle_interaction()
