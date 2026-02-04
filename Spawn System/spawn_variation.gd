extends Resource
class_name SpawnVariation

@export var _name : String = ""
@export var _group : String = ""
@export var _timer : float = 0
@export var _time_limit : float = 1
@export var _scene : PackedScene = null

@export var _active : bool = false
@export var _use_active_function : bool = false
@export var _active_function : Callable = Callable()

var _spawner : Node2D = null

@export var _remaining : int = -1
@export var _limit : int = -1
@export var _alive : int = 0
@export var _total : int = 0

@export var _proportion : float = 0
@export var _position : Vector2 = Vector2.ZERO

func _update(delta) -> void:
	if !_active || (_use_active_function && !_active_function.call()):
		return
	
	if _timer > 0:
		_timer -= delta
	else:
		_timer = _time_limit
		_spawn()

func _spawn() -> void:
	if _remaining != -1 && _remaining == 0:
		return
	if _limit != -1 && _alive >= _limit:
		return
	if !_spawner || !_spawner.get_tree():
		return

	var instance : Node2D = _scene.instantiate()
	if _name:
		instance.name = "{x}_{y}".format({"x": _name, "y": _total})
	if _group:
		instance.add_to_group(_group)
	instance.tree_exited.connect(func(): _alive -= 1)

	_spawner.add_child(instance)
	instance.global_position = _position
	_total += 1
	_alive += 1
	if _remaining > 0:
		_remaining -= 1
