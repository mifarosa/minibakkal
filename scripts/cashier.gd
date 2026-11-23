extends Node3D
## Checkout counter. Serves the first customer in line when the player stands nearby (or a cashier is hired).

var auto := false  # true once a cashier has been hired
var queue: Array = []
var _player: Node3D = null
var _serve_timer := 0.0
var _npc: Node3D


func _ready() -> void:
	add_child(Models.counter())
	var a := Game.zone(self, 2.4)
	a.body_entered.connect(func(b): if b is CharacterBody3D: _player = b)
	a.body_exited.connect(func(b): if b == _player: _player = null)
	_npc = Models.person(Color(0.8, 0.3, 0.8), Color(0.2, 0.2, 0.3))
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
		_fly_coins(first.global_position)
		first.finish()


func _pop_text(t: String, at: Vector3) -> void:
	var l := Game.label(t, Vector3.ZERO, 56, false)
	l.modulate = Color(0.4, 1.0, 0.4)
	get_tree().current_scene.add_child(l)
	l.global_position = at + Vector3(0, 2.6, 0)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y + 1.5, 0.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8)
	tw.tween_callback(l.queue_free)


## Coins arc from the customer to the money counter in the HUD corner.
func _fly_coins(from: Vector3) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var target := cam.project_position(Vector2(vp.x * 0.09, vp.y * 0.04), 40.0)
	for i in 3:
		var c := Models.coin()
		get_tree().current_scene.add_child(c)
		c.global_position = from + Vector3(0, 1.6, 0)
		c.scale = Vector3.ONE * 1.5
		var tw := c.create_tween()
		tw.tween_interval(i * 0.1)
		tw.tween_method(_coin_step.bind(c, c.global_position, target), 0.0, 1.0, 0.7).set_ease(Tween.EASE_IN)
		tw.tween_callback(c.queue_free)


func _coin_step(t: float, c: Node3D, start: Vector3, target: Vector3) -> void:
	var p := start.lerp(target, t)
	p.y += sin(t * PI) * 2.5
	c.global_position = p
	c.rotation.z = t * 14.0
