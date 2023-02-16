extends Node3D


@export_node_path("Trigger") var _target_path
@export var _press_time := 1.0

@onready var _n_target : Trigger
@onready var _n_timer : Timer = $Timer

var _pressed := false


## Private methods ##

func _ready() -> void:
	if _target_path != null:
		_n_target = get_node_or_null(_target_path)
	_n_timer.set_wait_time(_press_time)


func _on_interact_area_interacted() -> void:
	if not _pressed and _n_target != null:
		_pressed = true
		_n_target.activate()
		_n_timer.start()
		await _n_timer.timeout
		_n_target.deactivate()
		_pressed = false
