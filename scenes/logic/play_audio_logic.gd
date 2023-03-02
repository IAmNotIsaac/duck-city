extends Logic


@export_node_path("AudioStreamPlayer3D", "AudioStreamPlayer2D", "AudioStreamPlayer") var _audio_path


func _on_activated() -> void:
	if _audio_path != null:
		get_node(_audio_path).play()
