class_name Models
extends RefCounted
## Procedural low-poly models built from toon-shaded primitives. All models face +Z and sit on y = 0.

const SKIN := Color(1.0, 0.8, 0.62)
const WOOD := Color(0.72, 0.45, 0.22)
const WOOD_LIGHT := Color(0.9, 0.65, 0.35)
const LEAF := Color(0.25, 0.7, 0.22)
const SOIL := Color(0.45, 0.28, 0.14)


static func _n(pos: Vector3 = Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	return n


# ---------- items (about 0.4 units tall, centered on the origin) ----------

static func item(product: String) -> Node3D:
	match product:
		"tomato": return tomato()
		"corn": return corn()
		"egg": return egg()
	return Game.box(Vector3(0.4, 0.4, 0.4), Game.color_of(product))


static func tomato() -> Node3D:
	var n := _n()
	n.add_child(Game.sphere(0.2, Color(0.93, 0.2, 0.18)))
	n.add_child(Game.box(Vector3(0.16, 0.05, 0.16), LEAF, Vector3(0, 0.19, 0), 0.02))
	return n


static func corn() -> Node3D:
	var n := _n()
	n.add_child(Game.capsule(0.11, 0.46, Color(1.0, 0.85, 0.15), Vector3(0, 0, 0)))
	for side in [-1.0, 1.0]:
		var leaf := Game.box(Vector3(0.05, 0.34, 0.14), LEAF, Vector3(side * 0.1, -0.04, 0), 0.02)
		leaf.rotation.z = -side * 0.25
		n.add_child(leaf)
	return n


static func egg() -> Node3D:
	var n := _n()
	var e := Game.sphere(0.17, Color(0.98, 0.96, 0.9))
	e.scale = Vector3(1.0, 1.25, 1.0)
	n.add_child(e)
	return n


# ---------- people ----------

## Returns a character. `body` meta holds the node to bob while walking.
static func person(shirt: Color, hat: Color, with_hat: bool = true) -> Node3D:
	var root := _n()
	var body := _n()
	root.add_child(body)
	root.set_meta("body", body)
	body.add_child(Game.capsule(0.34, 1.05, shirt, Vector3(0, 0.62, 0)))
	body.add_child(Game.sphere(0.3, SKIN, Vector3(0, 1.38, 0)))
	if with_hat:
		body.add_child(Game.cylinder(0.33, 0.14, hat, Vector3(0, 1.64, 0)))
	else:
		body.add_child(Game.sphere(0.31, hat, Vector3(0, 1.45, -0.05)))
	for side in [-1.0, 1.0]:
		body.add_child(Game.sphere(0.04, Color(0.1, 0.08, 0.08), Vector3(side * 0.11, 1.4, 0.27), 0.0))
		body.add_child(Game.sphere(0.1, SKIN, Vector3(side * 0.38, 0.8, 0.1), 0.03))
	return root


static func bob(person_node: Node3D, time: float, moving: bool) -> void:
	var body: Node3D = person_node.get_meta("body")
	body.position.y = absf(sin(time * 11.0)) * 0.09 if moving else 0.0
	body.rotation.z = sin(time * 11.0) * 0.06 if moving else 0.0


static func chicken() -> Node3D:
	var n := _n()
	n.add_child(Game.sphere(0.36, Color(0.99, 0.98, 0.95), Vector3(0, 0.36, 0)))
	n.add_child(Game.sphere(0.2, Color(0.99, 0.98, 0.95), Vector3(0, 0.72, 0.3)))
	n.add_child(Game.box(Vector3(0.1, 0.06, 0.14), Color(1.0, 0.6, 0.1), Vector3(0, 0.7, 0.5), 0.02))
	n.add_child(Game.box(Vector3(0.06, 0.12, 0.14), Color(0.9, 0.15, 0.15), Vector3(0, 0.93, 0.3), 0.02))
	for side in [-1.0, 1.0]:
		n.add_child(Game.sphere(0.03, Color(0.05, 0.05, 0.05), Vector3(side * 0.1, 0.76, 0.42), 0.0))
	return n


# ---------- stations ----------

## Growing bed for a producer: crops for tomato/corn, a straw nest with chickens for egg.
static func bed(product: String) -> Node3D:
	var n := _n()
	if product == "egg":
		n.add_child(Game.cylinder(1.25, 0.18, Color(0.95, 0.75, 0.25), Vector3(0, 0.09, -0.1)))
		for x in [-0.55, 0.45]:
			var c := chicken()
			c.position = Vector3(x, 0.15, -0.2)
			c.rotation.y = x * 0.8
			n.add_child(c)
		return n
	n.add_child(Game.box(Vector3(2.7, 0.3, 1.1), SOIL, Vector3(0, 0.15, -0.25)))
	n.add_child(Game.box(Vector3(2.8, 0.1, 1.2), WOOD, Vector3(0, 0.3, -0.25), 0.04))
	var plants: Array = []
	for x in [-0.9, 0.0, 0.9]:
		var plant := _n(Vector3(x, 0.35, -0.25))
		plant.add_child(Game.cylinder(0.05, 0.6, LEAF, Vector3(0, 0.3, 0), 0.02))
		plant.add_child(Game.sphere(0.25, LEAF, Vector3(0, 0.7, 0), 0.03))
		var fruit := item(product)
		fruit.position = Vector3(0.2, 0.62, 0.15)
		plant.add_child(fruit)
		plant.set_meta("fruit", fruit)
		plants.append(plant)
		n.add_child(plant)
	n.set_meta("plants", plants)
	return n


static func shelf() -> Node3D:
	var n := _n()
	n.add_child(Game.box(Vector3(2.6, 1.1, 1.0), WOOD, Vector3(0, 0.55, 0)))
	n.add_child(Game.box(Vector3(2.8, 0.12, 1.15), WOOD_LIGHT, Vector3(0, 1.16, 0.02), 0.04))
	n.add_child(Game.box(Vector3(2.8, 0.35, 0.1), WOOD, Vector3(0, 1.4, -0.5), 0.04))
	return n


static func counter() -> Node3D:
	var n := _n()
	n.add_child(Game.box(Vector3(3.0, 1.0, 1.0), Color(0.35, 0.8, 0.68), Vector3(0, 0.5, 0)))
	n.add_child(Game.box(Vector3(3.2, 0.12, 1.2), Color(0.95, 0.95, 0.9), Vector3(0, 1.06, 0), 0.04))
	n.add_child(Game.box(Vector3(0.7, 0.4, 0.5), Color(0.25, 0.27, 0.35), Vector3(0.7, 1.32, 0)))
	var screen := Game.box(Vector3(0.5, 0.3, 0.05), Color(0.6, 0.95, 1.0), Vector3(0.7, 1.6, 0.05), 0.02)
	screen.rotation.x = -0.4
	n.add_child(screen)
	return n


static func tree(scale_factor: float = 1.0) -> Node3D:
	var n := _n()
	n.add_child(Game.cylinder(0.25, 1.4, Color(0.55, 0.35, 0.2), Vector3(0, 0.7, 0)))
	n.add_child(Game.sphere(1.1, Color(0.3, 0.75, 0.25), Vector3(0, 2.0, 0)))
	n.add_child(Game.sphere(0.8, Color(0.35, 0.8, 0.3), Vector3(0.4, 2.7, 0.2)))
	n.scale = Vector3.ONE * scale_factor
	return n


static func bush() -> Node3D:
	var n := _n()
	n.add_child(Game.sphere(0.6, Color(0.3, 0.72, 0.25), Vector3(0, 0.45, 0)))
	n.add_child(Game.sphere(0.45, Color(0.35, 0.78, 0.3), Vector3(0.5, 0.35, 0.1)))
	return n


static func coin() -> MeshInstance3D:
	var c := Game.cylinder(0.14, 0.05, Color(1.0, 0.82, 0.15), Vector3.ZERO, 0.02)
	c.rotation.x = PI / 2.0
	return c


static func fence(a: Vector3, b: Vector3) -> Node3D:
	var n := _n()
	var length := a.distance_to(b)
	var dir := (b - a).normalized()
	var posts := int(length / 1.5)
	for i in posts + 1:
		var at := a + dir * minf(i * 1.5, length)
		n.add_child(Game.box(Vector3(0.2, 1.0, 0.2), WOOD_LIGHT, at + Vector3(0, 0.5, 0), 0.04))
	for h in [0.4, 0.8]:
		var rail := Game.box(Vector3(0.08, 0.1, length), WOOD, (a + b) / 2.0 + Vector3(0, h, 0), 0.0)
		rail.rotation.y = atan2(dir.x, dir.z)
		n.add_child(rail)
	return n


## Scale-in "pop" animation for a node that is already in the tree.
static func pop(n: Node3D, time: float = 0.2) -> void:
	n.scale = Vector3.ONE * 0.01
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector3.ONE, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
