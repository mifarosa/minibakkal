extends Node3D
## Display shelf: the player drops products in, customers take them out.

var product := "tomato"
var capacity := 8
var stock := 0
var _player: Node3D = null
var _give_timer := 0.0
var _label: Label3D
var _items := Node3D.new()


func setup(p: String, cap: int = 8) -> void:
	product = p
	capacity = cap


func stand_point() -> Vector3:
	return global_position + Vector3(0, 0, 1.8)


func _ready() -> void:
	add_child(Game.box(Vector3(2.6, 1.2, 1.0), Color(0.62, 0.4, 0.2), Vector3(0, 0.6, 0)))
	add_child(_items)
	_label = Game.label("0/%d" % capacity, Vector3(0, 2.4, 0), 40)
	add_child(_label)
	var a := Game.zone(self, 2.4)
	a.body_entered.connect(func(b): if b is CharacterBody3D: _player = b)
	a.body_exited.connect(func(b): if b == _player: _player = null)
	_refresh()


func _process(delta: float) -> void:
	if _player and stock < capacity and _player.has_item(product):
		_give_timer -= delta
		if _give_timer <= 0.0:
			_give_timer = 0.12
			_player.take_item(product)
			stock += 1
			_refresh()


func free_space() -> int:
	return capacity - stock


func add_items(n: int) -> void:
	stock = mini(stock + n, capacity)
	_refresh()


func take_one() -> bool:
	if stock <= 0:
		return false
	stock -= 1
	_refresh()
	return true


func _refresh() -> void:
	_label.text = "%d/%d" % [stock, capacity]
	for c in _items.get_children():
		c.queue_free()
	for i in stock:
		_items.add_child(Game.box(Vector3(0.45, 0.3, 0.45), Game.color_of(product),
			Vector3(-1.0 + (i % 4) * 0.62, 1.35 + (i / 4) * 0.35, 0)))
