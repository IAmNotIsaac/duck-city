@tool
extends AudioStreamPlayer3D


const _INVERSE_SQUARE_SLOPE := 0.25

@export_range(0.0, 8.0, 0.1, "or_greater") var _radius : float = 1.0:
	set = set_radius

@onready var _n_area := $Area3D
@onready var _n_col := $Area3D/CollisionShape3D


## Private methods ##

func _ready() -> void:
	_n_col.shape = SphereShape3D.new()
	set_radius(_radius)


func _alert_avian_mechs() -> void:
	for body in _n_area.get_overlapping_bodies():
		if body is AvianMech:
			body.alert(get_global_position())


func _process(delta : float) -> void:
	if playing:
		_alert_avian_mechs()


## Public methods ##

func set_radius(value : float) -> void:
	if not is_inside_tree():
		await ready
	
	_radius = value
	_n_col.shape.set_radius.call_deferred(value)
	match attenuation_model:
		ATTENUATION_INVERSE_SQUARE_DISTANCE:
			unit_size = value * _INVERSE_SQUARE_SLOPE
