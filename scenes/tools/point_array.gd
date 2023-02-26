@tool
class_name PointArray
extends Node


## Private methods ##

func _ready() -> void:
	for child in get_children():
		if not child is Marker3D:
			child.queue_free()


func _on_child_entered_tree(_node : Node) -> void:
	update_configuration_warnings()


func _on_child_exiting_tree(_node : Node) -> void:
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	if len(get_children()) != 0:
		var warnings : PackedStringArray = []
		
		for child in get_children():
			if not child is Marker3D:
				warnings.push_back("%s should be an instance of Marker3D. All other nodes will be ignored and deleted on runtime." % child.get_name())
		
		return warnings
	
	else:
		return ["%s is useless without several Marker3Ds that serve as locations for AvianMechs to visit." % get_name()]


## Public methods ##

func get_wander_points() -> PackedVector3Array:
	var res : PackedVector3Array = []
	
	for child in get_children():
		res.push_back(child.get_global_position())
	
	return res
