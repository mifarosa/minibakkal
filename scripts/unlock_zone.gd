extends Node3D
## Pay-to-unlock pad. Stand on it to pay; when fully paid `unlocked` fires.

signal unlocked

var id := ""
var cost := 100
var remaining := 100
var _player: Node3D = null
var _tick := 0.0
var _label: Label3D


func setup(unlock_id: String, price: int) -> void:
	id = unlock_id
	cost = price
	remaining = price


func _ready() -> void:
	add_child(Game.box(Vector3(2.2, 0.05, 2.2), Color(1, 1, 1, 1), Vector3(0, 0.03, 0)))
	_label = Game.label("$%d" % remaining, Vector3(0, 1.6, 0), 56)
	add_child(_label)
	var a := Game.zone(self, 1.3)
	a.body_entered.connect(func(b): if b is CharacterBody3D: _player = b)
	a.body_exited.connect(func(b): if b == _player: _player = null)


func _process(delta: float) -> void:
	if not _player or remaining <= 0:
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 0.03
	var chunk := mini(maxi(1, cost / 40), remaining)
	if Game.spend(chunk):
		remaining -= chunk
		_label.text = "$%d" % remaining
		if remaining <= 0:
			Game.unlocked[id] = true
			unlocked.emit()
			queue_free()
