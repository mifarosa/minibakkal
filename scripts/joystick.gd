extends Control
## Floating virtual joystick (mouse events; Godot emulates mouse from touch by default).

const RADIUS := 110.0

var _active := false
var _origin := Vector2.ZERO
var _pos := Vector2.ZERO


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_active = e.pressed
		_origin = e.position
		_pos = e.position
		if not _active:
			Game.move_vec = Vector2.ZERO
		queue_redraw()
	elif e is InputEventMouseMotion and _active:
		_pos = e.position
		Game.move_vec = ((_pos - _origin) / RADIUS).limit_length(1.0)
		queue_redraw()


func _draw() -> void:
	if not _active:
		return
	draw_circle(_origin, RADIUS, Color(1, 1, 1, 0.15))
	draw_circle(_origin + (_pos - _origin).limit_length(RADIUS), 45.0, Color(1, 1, 1, 0.5))
