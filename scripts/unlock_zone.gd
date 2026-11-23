extends Node3D
## Pay-to-unlock pad. Stand on it to pay; when fully paid `unlocked` fires.

signal unlocked

var id := ""
var cost := 100
var remaining := 100
var _player: Node3D = null
var _tick := 0.0
var _label: Label3D
var _pad: Node3D
var _fill: Node3D


func setup(unlock_id: String, price: int) -> void:
	id = unlock_id
	cost = price
	remaining = price


func _ready() -> void:
	_pad = Game.box(Vector3(2.2, 0.05, 2.2), Color(1, 1, 1, 1), Vector3(0, 0.03, 0), 0.0)
	add_child(_pad)
	_fill = Game.box(Vector3(2.0, 0.06, 2.0), Color(0.35, 0.85, 0.3), Vector3(0, 0.05, 0), 0.0)
	_fill.scale = Vector3(0.001, 1, 0.001)
	add_child(_fill)
	var pulse := create_tween().set_loops()
	pulse.tween_property(_pad, "scale", Vector3(1.06, 1, 1.06), 0.7).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_pad, "scale", Vector3.ONE, 0.7).set_trans(Tween.TRANS_SINE)
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
		var f := 1.0 - float(remaining) / float(cost)
		_fill.scale = Vector3(maxf(f, 0.001), 1, maxf(f, 0.001))
		if remaining <= 0:
			Game.unlocked[id] = true
			unlocked.emit()
			set_process(false)
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw.tween_callback(queue_free)
