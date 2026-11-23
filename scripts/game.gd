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


const TOON := preload("res://shaders/toon.gdshader")
const OUTLINE := preload("res://shaders/outline.gdshader")

var _mat_cache: Dictionary = {}
var _outline_mats: Dictionary = {}


## Toon material for a color, with a black outline pass. Cached per (color, outline thickness).
func toon_mat(color: Color, outline: float = 0.08) -> ShaderMaterial:
	var key := str(color.to_html(), "_", outline)
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("albedo_color", color)
	if outline > 0.0:
		if not _outline_mats.has(outline):
			var o := ShaderMaterial.new()
			o.shader = OUTLINE
			o.set_shader_parameter("thickness", outline)
			_outline_mats[outline] = o
		m.next_pass = _outline_mats[outline]
	_mat_cache[key] = m
	return m


func _mesh_node(mesh: Mesh, color: Color, pos: Vector3, outline: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = toon_mat(color, outline)
	m.position = pos
	return m


func box(size: Vector3, color: Color, pos: Vector3 = Vector3.ZERO, outline: float = 0.08) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh_node(mesh, color, pos, outline)


func capsule(radius: float, height: float, color: Color, pos: Vector3 = Vector3.ZERO, outline: float = 0.08) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	return _mesh_node(mesh, color, pos, outline)


func sphere(radius: float, color: Color, pos: Vector3 = Vector3.ZERO, outline: float = 0.06) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	return _mesh_node(mesh, color, pos, outline)


func cylinder(radius: float, height: float, color: Color, pos: Vector3 = Vector3.ZERO, outline: float = 0.06) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	return _mesh_node(mesh, color, pos, outline)


func label(text: String, pos: Vector3, size: int = 48, badge: bool = true) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = size
	l.pixel_size = 0.012
	l.outline_size = 12
	l.no_depth_test = true
	l.render_priority = 1
	if badge:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(maxf(float(text.length()), 4.0) * size * 0.55 * 0.012 + 0.25, size * 1.25 * 0.012)
		q.mesh = qm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.05, 0.05, 0.12, 0.6)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.no_depth_test = true
		q.material_override = mat
		l.add_child(q)
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
