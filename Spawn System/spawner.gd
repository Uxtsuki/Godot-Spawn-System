extends Node2D
class_name Spawner

var _RNG : RandomNumberGenerator = RandomNumberGenerator.new()
@export var _active : bool = false
@export var _use_active_function : bool = false
@export var _active_function : Callable = Callable()
@export var _auto_next_wave : bool = true

@export var _wave : Dictionary[int, Array] = {
	0: [
		{
			"type": WAVE_ACTION.SPAWN,
			"entity": "",
			"position": null,
			"repetition": 1,
			"min_time_gap": 1/15.0,
			"parent": null
		},
		{
			"type": WAVE_ACTION.WAIT,
			"time": 0.5,
		},
	]
}
@export var _current_wave : int = 1
var _on_action : bool = false
enum WAVE_ACTION { SPAWN, WAIT } 

@export var _options : Array[SpawnOption] = []

func _process(delta: float) -> void:
	if !_active && (_use_active_function && !_active_function.call()):
		return
	if _wave.size() > 0:
		_next_action()
	elif _options.size() > 0:
		for O in _options:
			if O._spawner != self:
				O._spawner = self
			if O._RNG != _RNG:
				O._RNG = _RNG
			O._update(delta)

func _next_action() -> void:
	if !_wave.has(_current_wave) || _on_action:
		return

	_on_action = true
	var _action : Dictionary = _wave[_current_wave].pop_front()
	match _action["type"]:
		WAVE_ACTION.WAIT:
			await get_tree().create_timer(_action["time"]).timeout
		WAVE_ACTION.SPAWN:
			if _action["entity"] != "":
				var times : int = 1 if !_action.has("repetition") else  _action["repetition"]
				for I in range(0,times):
					var instance : SpawnVariation = load(_action["entity"])
					instance._spawner = get_tree().current_scene if !_action.has("parent") else _action.has("parent")
					if _action.has("position") && _action["position"]:
						instance._position = _action["position"]
					instance._spawn()
					if _action.has("min_time_gap") && _action["min_time_gap"]:
						await get_tree().create_timer(_action["min_time_gap"]).timeout

	if _wave[_current_wave].size() == 0:
		_wave.erase(_current_wave)
		if _auto_next_wave:
			_next_wave()
	
	_on_action = false

func _next_wave() -> void:
	if _wave.size() > 0 && _wave.has(_current_wave + 1):
		_current_wave += 1

func _load_wave(_file_path : String) -> void:
	if !FileAccess.file_exists(_file_path):
		return
	var file : FileAccess = FileAccess.open(_file_path, FileAccess.READ)
	var data : Dictionary = JSON.parse_string(file.get_as_text())
	_wave = {}
	for i in data:
		for action in data[i]:
			action["type"] = int(action["type"])
			if !action.has("position") && !action.has("x"):
				continue

			var position : Vector2 = Vector2(action["x"], action["y"])
			action.erase("x")
			action.erase("y")
			action["position"] = position
		_wave[int(i)] = data[i]
