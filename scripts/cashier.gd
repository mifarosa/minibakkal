extends Node3D
## Checkout counter. Serves the first customer in line when the player stands nearby (or a cashier is hired).

var auto := false  # true once a cashier has been hired
var queue: Array = []
var _player: Node3D = null
var _serve_timer := 0.0
var _npc: Node3D


func _ready() -> void:
	add_child(Game.box(Vector3(3.0, 1.0, 1.0), Color(0.45, 0.85, 0.7), Vector3(0, 0.5, 0)))
	add_child(Game.box(Vector3(0.7, 0.5, 0.5), Color(0.2, 0.2, 0.25), Vector3(0.7, 1.25, 0)))
	var a := Game.zone(self, 2.4)
	a.body_entered.connect(func(b): if b is CharacterBody3D: _player = b)
	a.body_exited.connect(func(b): if b == _player: _player = null)
	_npc = Node3D.new()
	_npc.add_child(Game.capsule(0.4, 1.4, Color(0.8, 0.3, 0.8), Vector3(0, 0.8, 0)))
	_npc.position = Vector3(0, 0, -1.2)
	_npc.visible = false
	add_child(_npc)


func set_auto(on: bool) -> void:
	auto = on
	_npc.visible = on


func queue_point(i: int) -> Vector3:
	return global_position + Vector3(2.4 + i * 1.0, 0, 0)


func join(c: Node3D) -> void:
	queue.append(c)


func _process(delta: float) -> void:
	if queue.is_empty():
		_serve_timer = 0.0
		return
	var first = queue[0]
	if not first.arrived or not (auto or _player):
		return
	_serve_timer += delta
	if _serve_timer >= 0.6:
		_serve_timer = 0.0
		queue.pop_front()
		var price := Game.price_of(first.wanted)
		Game.add_money(price)
		_pop_text("+%d" % price, first.global_position)
		first.finish()


func _pop_text(t: String, at: Vector3) -> void:
	var l := Game.label(t, Vector3.ZERO, 56)
	l.modulate = Color(0.4, 1.0, 0.4)
	get_tree().current_scene.add_child(l)
	l.global_position = at + Vector3(0, 2.6, 0)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y + 1.5, 0.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8)
	tw.tween_callback(l.queue_free)
