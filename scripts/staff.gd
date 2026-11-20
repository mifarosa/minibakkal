extends Node3D
## Hired worker: picks products up from producers and restocks the emptiest shelf automatically.

enum State { IDLE, TO_PRODUCER, TO_SHELF }

const CARRY := 4

var main: Node3D  # provides `producers` and `shelves`
var _state := State.IDLE
var _producer: Node3D
var _shelf: Node3D
var _carried := 0
var _product := ""
var _stack := Node3D.new()
var _think := 0.0


func _ready() -> void:
	add_child(Game.capsule(0.35, 1.3, Color(0.95, 0.55, 0.1), Vector3(0, 0.75, 0)))
	add_child(Game.box(Vector3(0.45, 0.12, 0.45), Color(1, 1, 1), Vector3(0, 1.5, 0)))
	_stack.position = Vector3(0, 1.0, 0.5)
	add_child(_stack)


func _process(delta: float) -> void:
	match _state:
		State.IDLE:
			_think -= delta
			if _think <= 0.0:
				_think = 0.5
				_plan()
		State.TO_PRODUCER:
			if _move_to(_producer.stand_point(), delta):
				var want := mini(CARRY, _shelf.free_space())
				while _carried < want and _producer.take_one():
					_carried += 1
				_refresh()
				_state = State.TO_SHELF if _carried > 0 else State.IDLE
		State.TO_SHELF:
			if _move_to(_shelf.stand_point(), delta):
				_shelf.add_items(_carried)
				_carried = 0
				_refresh()
				_state = State.IDLE


## Picks the emptiest shelf that has a producer with stock for it.
func _plan() -> void:
	var best: Node3D = null
	var best_ratio := 1.0
	for s in main.shelves:
		if s.free_space() <= 0:
			continue
		var ratio := float(s.stock) / float(s.capacity)
		if ratio < best_ratio and _find_producer(s.product) != null:
			best = s
			best_ratio = ratio
	if best == null:
		return
	_shelf = best
	_product = best.product
	_producer = _find_producer(_product)
	_state = State.TO_PRODUCER


func _find_producer(product: String) -> Node3D:
	var top: Node3D = null
	for p in main.producers:
		if p.product == product and p.stock > 0 and (top == null or p.stock > top.stock):
			top = p
	return top


func _refresh() -> void:
	for c in _stack.get_children():
		c.queue_free()
	for i in _carried:
		_stack.add_child(Game.box(Vector3(0.4, 0.22, 0.4), Game.color_of(_product), Vector3(0, i * 0.25, 0)))


func _move_to(target: Vector3, delta: float) -> bool:
	var d := target - global_position
	d.y = 0
	if d.length() < 0.1:
		return true
	global_position += d.normalized() * min(Game.staff_speed() * delta, d.length())
	rotation.y = atan2(d.x, d.z)
	return false
