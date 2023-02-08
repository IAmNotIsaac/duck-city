@tool
extends Node3D


const _MATERIAL := preload("res://assets/materials/construction_space_material.tres")
const _STRUCTURE_BOUNDS := {
	Constants.Structure.Test1: [Vector2(10.0, 10.0), "Test 1"],
	Constants.Structure.Test2: [Vector2(1.0, 1.0),   "Test 2"],
}

@export var _structure_type := Constants.Structure.Test1:
	set(v):
		_structure_type = v
		_set_mesh_and_area_size(v)

var _interaction : InteractionData

@onready var _mesh := $MeshInstance3D
@onready var _area_shape := $Area3D/CollisionShape3D


func _ready() -> void:
	_mesh.mesh = BoxMesh.new()
	_mesh.mesh.material = _MATERIAL
	_area_shape.shape = BoxShape3D.new()
	
	_set_mesh_and_area_size(_structure_type)


func _set_mesh_and_area_size(structure : Constants.Structure) -> void:
	if is_inside_tree():
		var bounds : Vector2 = _STRUCTURE_BOUNDS[structure][0]
		_mesh.mesh.size = Vector3(bounds.x, 1.0, bounds.y)
		_area_shape.shape.size = Vector3(bounds.x, 1.0, bounds.y)


func _on_area_3d_body_entered(body : PhysicsBody3D) -> void:
	if body is Player:
		_interaction = InteractionData.new("Construct %s" % _STRUCTURE_BOUNDS[_structure_type][1])
		Stats.add_interact_prompt(_interaction)


func _on_area_3d_body_exited(body : PhysicsBody3D) -> void:
	if body is Player:
		Stats.erase_interact_prompt(_interaction)
		_interaction = null
