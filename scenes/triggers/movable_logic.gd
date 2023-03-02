extends Logic


enum FollowMode {
	Patrol,
	Cycle,
}

enum Direction {
	Forward,
	Backward,
	MAX
}

@export_node_path("PointArray") var _points_path : NodePath
@export var _follow_mode : FollowMode = FollowMode.Patrol
@export var _direction : Direction = Direction.Forward
@export var _path_index := 0
@export var _stop := true
@export var _speed := 1.0

@onready var _n_points : PointArray = get_node_or_null(_points_path)

var _progress := 0.0


## Private methods ##

func _flip_direction() -> void:
	@warning_ignore("int_as_enum_without_cast")
	_direction = wrapi(_direction + 1, 0, Direction.MAX)


func _path_pos() -> Vector3:
	return _n_points.get_wander_points()[_path_index]


func _next_path_pos() -> Vector3:
	var next : int
	
	match _direction:
		Direction.Forward: next = 1
		Direction.Backward: next = -1
	
	var idx : int = _path_index + next
	
	match _follow_mode:
		FollowMode.Patrol:
			if idx >= len(_n_points.get_wander_points()):
				idx = _path_index - next
			elif idx < 0:
				idx = _path_index + 1
		
		FollowMode.Cycle:
			idx = wrapi(idx, 0, len(_n_points.get_wander_points()))
	
	return _n_points.get_wander_points()[idx]


func _physics_process(delta : float) -> void:
	if not _stop and _n_points != null:
		var p1 := _path_pos()
		var p2 := _next_path_pos()
		
		global_position = p1.lerp(p2, _progress)
		_progress = min(_progress + _speed * delta, 1.0)
		
		if _progress == 1.0:
			_progress = 0.0
			var next : int
			
			match _direction:
				Direction.Forward: next = 1
				Direction.Backward: next = -1
			
			_path_index += next
			
			match _follow_mode:
				FollowMode.Patrol:
					if _path_index >= len(_n_points.get_wander_points()):
						_path_index -= next * 2
						_flip_direction()
					elif _path_index < 0:
						_path_index -= next * 2
						_flip_direction()
				
				FollowMode.Cycle:
					_path_index = wrapi(_path_index, 0, len(_n_points.get_wander_points()))


func _on_activated() -> void:
	_stop = false


func _on_deactivated() -> void:
	_stop = true
