extends Camera3D


@export_node_path("CameraTarget") var _target_path : NodePath

@onready var _target : CameraTarget = get_node_or_null(_target_path)


## Private methods ##

func _process(_delta : float) -> void:
	if _target != null:
		global_position = global_position.lerp(_target.global_position, _target.weight)
		global_rotation = Vector3(
			lerp_angle(global_rotation.x, _target.global_rotation.x, _target.weight),
			lerp_angle(global_rotation.y, _target.global_rotation.y, _target.weight),
			lerp_angle(global_rotation.z, _target.global_rotation.z, _target.weight)
		)
		h_offset = lerp(h_offset, _target.get_h_offset(), _target.weight)
		v_offset = lerp(v_offset, _target.get_v_offset(), _target.weight)
		cull_mask = _target.get_cull_mask()


## Public methods ##

func set_target(target : CameraTarget) -> void:
	_target = target
