class_name Trigger
extends Node3D


## Private methods ##


func _on_activated() -> void: pass
func _on_deactivated() -> void: pass


## Public methods ##


func activate() -> void:
	_on_activated()


func deactivate() -> void:
	_on_deactivated()
