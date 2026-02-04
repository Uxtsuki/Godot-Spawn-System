extends Node2D
class_name Entity

var _timer : float = 2
var _time_limit : float = 2

func _process(delta: float) -> void:
	if _timer > 0:
		_timer -= delta
	else:
		_timer = _time_limit
		#global_position = Vector2(
		#	randf_range(0, 1152),
		#	randf_range(0, 648)
		#)
