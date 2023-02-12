class_name AvianTarget
extends Node3D


@export var _enabled := true
@export var _avian_type := Constants.AvianType.AVIAN
@export_node_path("PhysicsBody3D") var collider_path = ^".."


func _init() -> void:
	add_to_group(Constants.AvianType.keys()[_avian_type] + "_target")


func enable() -> void:
	_enabled = true


func disable() -> void:
	_enabled = false


func is_enabled() -> bool:
	return _enabled


func get_collider() -> PhysicsBody3D:
	return get_node(collider_path)
