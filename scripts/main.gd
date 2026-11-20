extends Node3D
## Builds the whole store procedurally: world, camera, HUD, stations, unlock pads and customer spawner.

const PlayerScript := preload("res://scripts/player.gd")
const ProducerScript := preload("res://scripts/producer.gd")
const ShelfScript := preload("res://scripts/shelf.gd")
const CashierScript := preload("res://scripts/cashier.gd")
const CustomerScript := preload("res://scripts/customer.gd")
const UnlockScript := preload("res://scripts/unlock_zone.gd")
const JoystickScript := preload("res://scripts/joystick.gd")

const CAM_OFFSET := Vector3(12, 14, 12)
const ENTRANCE := Vector3(15, 0, 0)

var player: CharacterBody3D
var cam: Camera3D
var cashier: Node3D
var shelves: Array[Node3D] = []
var _money_label: Label
var _customers := 0


func _ready() -> void:
	Game.load_game()
	_build_environment()
	_build_stations()
	_build_hud()

	player = PlayerScript.new()
	player.position = Vector3(3, 0, 2)
	add_child(player)

	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.size = 26.0
	add_child(cam)
	_follow()

	var spawn := Timer.new()
	spawn.wait_time = 4.0
	spawn.autostart = true
	spawn.timeout.connect(_spawn_customer)
	add_child(spawn)

	var autosave := Timer.new()
	autosave.wait_time = 10.0
	autosave.autostart = true
	autosave.timeout.connect(Game.save_game)
	add_child(autosave)


func _process(_delta: float) -> void:
	_follow()


func _follow() -> void:
	# Blend between the player and the store center so the whole shop stays in view.
	var target := player.position * 0.5 + Vector3(5, 0, 0) * 0.5
	cam.position = target + CAM_OFFSET
	cam.look_at(target, Vector3.UP)


# ---------- world ----------

func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.74, 0.92, 0.4)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 0.15
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 45, 0)
	sun.light_energy = 0.55
	sun.shadow_enabled = true
	add_child(sun)

	# Grass ground (solid collider so nothing falls through)
	var ground := StaticBody3D.new()
	var gshape := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(80, 1, 80)
	gshape.shape = gbox
	gshape.position.y = -0.5
	ground.add_child(gshape)
	ground.add_child(Game.box(Vector3(80, 1, 80), Color(0.72, 0.92, 0.38), Vector3(0, -0.5, 0)))
	add_child(ground)

	# Store floor
	add_child(Game.box(Vector3(20, 0.1, 10), Color(1.0, 0.8, 0.5), Vector3(5, 0.05, -4)))
	# Back wall
	add_child(Game.box(Vector3(20, 3, 0.4), Color(0.85, 0.9, 0.9), Vector3(5, 1.5, -9.2)))


func _build_stations() -> void:
	cashier = CashierScript.new()
	cashier.position = Vector3(0, 0, -3)
	add_child(cashier)
	cashier.set_auto(Game.unlocked.has("cashier"))

	# Starting content: tomato field, chicken nest, tomato + egg shelves
	_add_producer("tomato", Vector3(-3, 0, 6), 4, 3.0)
	_add_producer("egg", Vector3(-8, 0, 6), 4, 4.0)
	_add_shelf("tomato", Vector3(6, 0, -7))
	_add_shelf("egg", Vector3(9.5, 0, -7))

	# Unlockable content
	_add_unlock("corn", 105, Vector3(6, 0, 3.5), func():
		var f := _add_producer("corn", Vector3(7, 0, 7), 4, 4.0)
		f.visible = true
		_add_shelf("corn", Vector3(13, 0, -7)))
	_add_unlock("tomato2", 300, Vector3(1, 0, 3.5), func():
		_add_producer("tomato", Vector3(1, 0, 7.5), 4, 2.5))
	_add_unlock("cashier", 200, Vector3(-3, 0, 0), func():
		cashier.set_auto(true))


func _add_producer(product: String, pos: Vector3, cap: int, every: float) -> Node3D:
	var p := ProducerScript.new()
	p.setup(product, cap, every)
	p.position = pos
	add_child(p)
	return p


func _add_shelf(product: String, pos: Vector3) -> Node3D:
	var s := ShelfScript.new()
	s.setup(product)
	s.position = pos
	add_child(s)
	shelves.append(s)
	return s


## Adds a pay pad; `on_unlock` builds the content. Already-unlocked pads rebuild their content on load.
func _add_unlock(id: String, cost: int, pos: Vector3, on_unlock: Callable) -> void:
	if Game.unlocked.has(id):
		on_unlock.call()
		return
	var z := UnlockScript.new()
	z.setup(id, cost)
	z.position = pos
	add_child(z)
	z.unlocked.connect(on_unlock)


# ---------- customers ----------

func _spawn_customer() -> void:
	if _customers >= 6 or shelves.is_empty():
		return
	var c := CustomerScript.new()
	var s: Node3D = shelves.pick_random()
	c.shelf = s
	c.wanted = s.product
	c.cashier = cashier
	c.exit_point = ENTRANCE
	c.position = ENTRANCE
	c.tree_exited.connect(func(): _customers -= 1)
	_customers += 1
	add_child(c)


# ---------- HUD ----------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var joy := JoystickScript.new()
	layer.add_child(joy)
	_money_label = Label.new()
	_money_label.add_theme_font_size_override("font_size", 56)
	_money_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_money_label.add_theme_constant_override("outline_size", 12)
	_money_label.position = Vector2(40, 40)
	_money_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_money_label)
	Game.money_changed.connect(func(v): _money_label.text = "$ %d" % v)
	_money_label.text = "$ %d" % Game.money
