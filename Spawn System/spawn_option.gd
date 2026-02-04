extends Resource
class_name SpawnOption

var _spawner : Node2D = null
var _RNG : RandomNumberGenerator = RandomNumberGenerator.new()
@export var _group : String = ""

@export var _active : bool = false
@export var _use_active_function : bool = false
@export var _active_function : Callable = Callable()

@export var _points : Array[NodePath] = []
@export var _points_weight : PackedFloat32Array = []

enum SPAWN_POINT_TYPE { ITERATION, RANDOM, RANDOM_WEIGHTED, AREA }
@export var _spawn_point : SPAWN_POINT_TYPE = SPAWN_POINT_TYPE.RANDOM
@export var _spawn_point_iterator : int = -1
@export var _spawn_point_is_parent : bool = true

enum SPAWN_DECISIOM_TYPE { ITERATION, RANDOM, RANDOM_WEIGHTED, WEIGHTED, ALIVE_WEIGHTED }
@export var _iterator : int = -1
@export var _weights : PackedFloat32Array = []
@export var _spawn_decision : SPAWN_DECISIOM_TYPE = SPAWN_DECISIOM_TYPE.ITERATION

@export var _variations : Array[SpawnVariation] = []

enum TIMER_OPTIONS { INDIVIDUAL, INCREMENTED, REPLACEABLE, COMMON }
@export var _timer_type : TIMER_OPTIONS = TIMER_OPTIONS.INDIVIDUAL

@export var _timer : float = 0
@export var _time_limit : float = 0

@export var _remaining : int = -1
@export var _limit : int = -1
@export var _total : int = 0
@export var _alive : int = 0
@export var _repetition : int = 0
@export var _min_time_gap : float = 1/15.0

func _update(delta : float) -> void:
	if _points.size() <= 0:
		return

	if _active || (_use_active_function && _active_function && _active_function.call()):
		match _timer_type:
			TIMER_OPTIONS.INDIVIDUAL:
				for I in _variations:
					if I._spawner != _spawner:
						I._spawner = _spawner
					I._update(delta)
			_:
				if _timer > 0:
					_timer -= delta
				if _timer <= 0:
					_spawn()


func _spawn() -> void:
	if (_limit != -1 && _alive >= _limit) || !_spawner || !_spawner.get_tree() || (_remaining != -1 && _remaining == 0):
		return

	for I in _variations:
		if I._spawner != _spawner:
			I._spawner = _spawner

	for P in _points:
		if !_spawner.get_tree().current_scene.has_node(P):
			return

	for I in range(0, _repetition):
		_total += 1
		_alive += 1
		if _remaining > 0:
			_remaining -= 1

		var _option : SpawnVariation = null
		match _spawn_decision:
			SPAWN_DECISIOM_TYPE.ITERATION:
				_iterator += 1 if _iterator < _variations.size() - 1 else -(_variations.size() - 1)
				_option = _variations[_iterator]
			[SPAWN_DECISIOM_TYPE.WEIGHTED, SPAWN_DECISIOM_TYPE.ALIVE_WEIGHTED]:
				var _number : float = _alive if _spawn_decision == SPAWN_DECISIOM_TYPE.ALIVE_WEIGHTED else _total
				for i in _variations:
					if i._proportion <= i._total / _number:
						_option = i
						break
			SPAWN_DECISIOM_TYPE.RANDOM_WEIGHTED:
				if _weights.size() >= 0:
					_option = _variations[_RNG.rand_weighted(_weights)]
			_:
				_option = _variations[_RNG.randi_range(0, _variations.size() - 1)]

		if _timer_type != TIMER_OPTIONS.INDIVIDUAL:
			match _timer_type:
				TIMER_OPTIONS.INCREMENTED:
					_timer = _time_limit + _option._time_limit
				TIMER_OPTIONS.REPLACEABLE:
					_timer = _option._time_limit
				_:
					_timer = _time_limit

		var _point : Node = null
		match _spawn_point:
				SPAWN_POINT_TYPE.ITERATION:
					_spawn_point_iterator += 1 if _spawn_point_iterator < _points.size() - 1 else -(_points.size() - 1)
					_point = _spawner.get_tree().current_scene.get_node(_points[_spawn_point_iterator])
				SPAWN_POINT_TYPE.RANDOM:
					_point = _spawner.get_tree().current_scene.get_node(_points[_RNG.randi_range(0, _points.size() - 1)])
				SPAWN_POINT_TYPE.RANDOM_WEIGHTED:
					_point = _spawner.get_tree().current_scene.get_node(_points[_RNG.rand_weighted(_points_weight)])
				_:
					_point = Node2D.new()
					var vectors : Array = [
						_spawner.get_tree().current_scene.get_node(_points[_RNG.randi_range(0, _points.size() - 1)]),
						_spawner.get_tree().current_scene.get_node(_points[_RNG.randi_range(0, _points.size() - 1)])
					]
					var point = Vector2(
						randf_range(vectors[0].global_position.x, vectors[1].global_position.x),
						randf_range(vectors[0].global_position.y, vectors[1].global_position.y),
					)
					_point.global_position = point

		if !_option || (_option._remaining != -1 && _option._remaining == 0) && (_option._limit != -1 && _option._alive >= _option._limit):
			return

		var instance = _option._scene.instantiate()
		instance.tree_exited.connect(
			func(): 
				_alive -= 1
				_option._alive -= 1)

		if _option._name:
			instance.name = "{x}_{y}".format({"x": _option._name, "y": _total})

		if _option._group:
			instance.add_to_group(_option._group)
			instance.add_to_group(_group)

		if _spawn_point_is_parent && _point.is_inside_tree():
			_point.add_child(instance)
		elif _spawn_point == SPAWN_POINT_TYPE.AREA:
			_spawner.get_tree().current_scene.add_child(instance)
			instance.global_position = _point.global_position
		elif _spawner:
			_spawner.add_child(instance)
		_option._total += 1
		_option._alive += 1
	
		if _option._remaining > 0:
			_option._remaining -= 1

		if _min_time_gap > 0 && _spawner:
			await _spawner.get_tree().create_timer(_min_time_gap).timeout
