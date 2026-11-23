extends CharacterBody3D
## Player: moves with joystick / WASD and carries a stack of products.


var carried: Array[String] = []
var _stack := Node3D.new()
var _max_label: Label3D
var _model: Node3D
var _t := 0.0
var _last_count := 0


func _ready() -> void:
	collision_layer = 1
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.6
	shape.shape = cap
	shape.position.y = 0.8
	add_child(shape)
	_model = Models.person(Color(0.25, 0.55, 0.95), Color(0.15, 0.15, 0.2))
	add_child(_model)
	_stack.position = Vector3(0, 1.0, 0.55)
	add_child(_stack)
	_max_label = Game.label("MAX", Vector3(0, 3.6, 0), 40)
	_max_label.visible = false
	add_child(_max_label)


func _physics_process(_delta: float) -> void:
	var input := Game.move_vec
	input.x += Input.get_axis("ui_left", "ui_right")
	input.y += Input.get_axis("ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): input.x -= 1.0
	if Input.is_key_pressed(KEY_D): input.x += 1.0
	if Input.is_key_pressed(KEY_W): input.y -= 1.0
	if Input.is_key_pressed(KEY_S): input.y += 1.0
	input = input.limit_length(1.0)
	# Rotate by the isometric camera yaw so "up" on screen is "up" in the world.
	var dir := Vector3(input.x, 0, input.y).rotated(Vector3.UP, PI / 4.0)
	velocity = dir * Game.player_speed()
	if dir.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 0.25)
	move_and_slide()
	_t += _delta
	Models.bob(_model, _t, dir.length() > 0.1)


func can_carry() -> bool:
	return carried.size() < Game.carry_capacity()


func add_item(product: String) -> void:
	carried.append(product)
	_refresh()


## Removes and returns the most recent item of the given product ("" if none).
func take_item(product: String) -> String:
	var i := carried.rfind(product)
	if i == -1:
		return ""
	carried.remove_at(i)
	_refresh()
	return product


func has_item(product: String) -> bool:
	return carried.has(product)


func _refresh() -> void:
	for c in _stack.get_children():
		c.queue_free()
	for i in carried.size():
		var it := Models.item(carried[i])
		it.position = Vector3(0, i * 0.4, 0)
		_stack.add_child(it)
		if i == carried.size() - 1 and carried.size() > _last_count:
			_pop(it)
	_last_count = carried.size()
	_max_label.visible = carried.size() >= Game.carry_capacity()


## Pop-in animation for a newly picked up item.
func _pop(n: Node3D) -> void:
	n.scale = Vector3.ZERO
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
