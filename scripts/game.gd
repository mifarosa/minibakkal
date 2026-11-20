extends Node
## Global state: wallet, unlocked content, save/load and small helpers.

signal money_changed(value: int)
signal upgrades_changed

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
var levels: Dictionary = {}  # upgrade id -> level

# id -> [display name, base cost, max level]
const UPGRADES := {
	"speed": ["Move speed", 100, 5],
	"capacity": ["Carry capacity", 150, 5],
	"staff": ["Staff speed", 200, 5],
	"income": ["Sale income", 250, 5],
}


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
		f.store_string(JSON.stringify({"money": money, "unlocked": unlocked, "levels": levels}))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary:
		money = int(data.get("money", 0))
		unlocked = data.get("unlocked", {})
		levels = data.get("levels", {})
	money_changed.emit(money)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()


# ---- upgrades ----

func level(id: String) -> int:
	return int(levels.get(id, 0))


func upgrade_cost(id: String) -> int:
	return roundi(UPGRADES[id][1] * pow(1.7, level(id)))


func is_maxed(id: String) -> bool:
	return level(id) >= UPGRADES[id][2]


func buy_upgrade(id: String) -> bool:
	if is_maxed(id) or not spend(upgrade_cost(id)):
		return false
	levels[id] = level(id) + 1
	upgrades_changed.emit()
	return true


func player_speed() -> float:
	return 6.0 * (1.0 + 0.12 * level("speed"))


func carry_capacity() -> int:
	return 8 + 2 * level("capacity")


func staff_speed() -> float:
	return 4.0 * (1.0 + 0.2 * level("staff"))


# ---- helpers ----

func color_of(product: String) -> Color:
	return PRODUCTS[product][0]


func price_of(product: String) -> int:
	return roundi(PRODUCTS[product][1] * (1.0 + 0.15 * level("income")))


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
	l.pixel_size = 0.012
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
