class_name AvianTarget
extends Node3D


signal damaged(damage_data : Damage)

@export var _enabled := true
@export var _avian_type := Constants.AvianType.AVIAN
@export_node_path("PhysicsBody3D") var collider_path = ^".."


## Private methods ##

func _init() -> void:
	add_to_group(Constants.AvianType.keys()[_avian_type] + "_target")


## Public methods

func enable() -> void:
	_enabled = true


func disable() -> void:
	_enabled = false


func is_enabled() -> bool:
	return _enabled


func get_collider() -> PhysicsBody3D:
	return get_node(collider_path)


func damage(damage_data : Damage) -> void:
	damaged.emit(damage_data)
