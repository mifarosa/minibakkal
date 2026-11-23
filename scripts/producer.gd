extends Node3D
## Field / chicken nest: produces a product over time, the player collects it by standing nearby.

var product := "tomato"
var capacity := 4
var interval := 3.0

var stock := 0
var _timer := 0.0
var _give_timer := 0.0
var _player: Node3D = null
var _label: Label3D
var _items := Node3D.new()
var _bed: Node3D


func setup(p: String, cap: int, every: float) -> void:
	product = p
	capacity = cap
	interval = every


func _ready() -> void:
	_bed = Models.bed(product)
	add_child(_bed)
	var icon := Models.item(product)
	icon.position = Vector3(-0.75, 2.2, 0)
	add_child(icon)
	add_child(_items)
	_label = Game.label("0/%d" % capacity, Vector3(0.3, 2.2, 0), 40)
	add_child(_label)
	var a := Game.zone(self, 2.0)
	a.body_entered.connect(func(b): if b is CharacterBody3D: _player = b)
	a.body_exited.connect(func(b): if b == _player: _player = null)
	_refresh()


func _process(delta: float) -> void:
	if stock < capacity:
		_timer += delta
		if _timer >= interval:
			_timer = 0.0
			stock += 1
			_refresh()
	if _player and stock > 0 and _player.can_carry():
		_give_timer -= delta
		if _give_timer <= 0.0:
			_give_timer = 0.15
			stock -= 1
			_player.add_item(product)
			_refresh()
	_grow()


func _grow() -> void:
	if not _bed.has_meta("plants"):
		return
	var g := clampf((float(stock) + _timer / interval) / float(capacity), 0.0, 1.0)
	for p in _bed.get_meta("plants"):
		p.scale = Vector3.ONE * (0.55 + 0.45 * g)
		(p.get_meta("fruit") as Node3D).visible = stock > 0 or g > 0.5


func take_one() -> bool:
	if stock <= 0:
		return false
	stock -= 1
	_refresh()
	return true


func stand_point() -> Vector3:
	return global_position + Vector3(0, 0, 1.6)


func _refresh() -> void:
	_label.text = "%d/%d" % [stock, capacity]
	for c in _items.get_children():
		c.queue_free()
	for i in stock:
		var it := Models.item(product)
		it.position = Vector3(-0.9 + i * 0.6, 0.45, 0.95)
		_items.add_child(it)
