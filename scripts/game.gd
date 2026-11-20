extends Node
## Global state: wallet, unlocked content, save/load and small helpers.

signal money_changed(value: int)

const SAVE_PATH := "user://save.json"

# Product id -> [color, sell price]
const PRODUCTS := {
	"tomato": [Color(0.92, 0.2, 0.2), 10],
	"corn": [Color(0.98, 0.85, 0.2), 8],
	"egg": [Color(0.97, 0.97, 0.92), 6],
}

var money: int = 0
var unlocked: Dictionary = {}  # unlock id -> true
var move_vec: Vector2 = Vector2.ZERO  # set by the virtual joystick


func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)


func spend(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"money": money, "unlocked": unlocked}))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary:
		money = int(data.get("money", 0))
		unlocked = data.get("unlocked", {})
	money_changed.emit(money)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()


# ---- helpers ----

func color_of(product: String) -> Color:
	return PRODUCTS[product][0]


func price_of(product: String) -> int:
	return PRODUCTS[product][1]


func box(size: Vector3, color: Color, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	m.material_override = mat
	m.position = pos
	return m


func capsule(radius: float, height: float, color: Color, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	m.material_override = mat
	m.position = pos
	return m


func label(text: String, pos: Vector3, size: int = 48) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = size
	l.outline_size = 12
	l.no_depth_test = true
	return l


## Creates a proximity trigger. Returns the Area3D (watch body_entered / body_exited).
func zone(parent: Node3D, radius: float) -> Area3D:
	var a := Area3D.new()
	var shape := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = radius
	s.height = 3.0
	shape.shape = s
	a.add_child(shape)
	a.collision_mask = 1
	parent.add_child(a)
	return a


func set_active(n: Node3D, on: bool) -> void:
	n.visible = on
	n.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
