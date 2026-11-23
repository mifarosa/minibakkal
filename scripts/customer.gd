extends Node3D
## Customer AI: shelf -> checkout queue -> exit. Moves in straight lines (open floor, no navmesh needed).

enum State { TO_SHELF, WAIT_STOCK, TO_QUEUE, LEAVING }

const SPEED := 3.0

var wanted := "tomato"
var shelf: Node3D
var cashier: Node3D
var exit_point := Vector3.ZERO
var arrived := false

var _state := State.TO_SHELF
var _wait := 0.0
var _bubble: Label3D
var _model: Node3D
var _t := 0.0
var _moving := false


func _ready() -> void:
	var col := Color.from_hsv(randf(), 0.6, 0.95)
	_model = Models.person(col, Color.from_hsv(randf(), 0.5, 0.6), randf() < 0.5)
	add_child(_model)
	_bubble = Game.label("?", Vector3(0, 2.4, 0), 36)
	_bubble.modulate = Game.color_of(wanted)
	add_child(_bubble)


func _process(delta: float) -> void:
	_t += delta
	_moving = false
	match _state:
		State.TO_SHELF:
			if _move_to(shelf.stand_point(), delta):
				_state = State.WAIT_STOCK
		State.WAIT_STOCK:
			if shelf.take_one():
				cashier.join(self)
				_state = State.TO_QUEUE
				arrived = false
			else:
				_wait += delta
				if _wait > 25.0:  # give up
					_leave()
		State.TO_QUEUE:
			var i: int = cashier.queue.find(self)
			if i == -1:
				return
			arrived = _move_to(cashier.queue_point(i), delta)
		State.LEAVING:
			if _move_to(exit_point, delta):
				queue_free()
	Models.bob(_model, _t, _moving)


func finish() -> void:
	_leave()


func _leave() -> void:
	_state = State.LEAVING
	_bubble.visible = false


func _move_to(target: Vector3, delta: float) -> bool:
	var d := target - global_position
	d.y = 0
	if d.length() < 0.1:
		return true
	_moving = true
	global_position += d.normalized() * min(SPEED * delta, d.length())
	rotation.y = atan2(d.x, d.z)
	return false
