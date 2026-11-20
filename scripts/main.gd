extends Node3D
## Builds the whole store procedurally: world, camera, HUD, stations, unlock pads and customer spawner.

const PlayerScript := preload("res://scripts/player.gd")
const ProducerScript := preload("res://scripts/producer.gd")
const ShelfScript := preload("res://scripts/shelf.gd")
const CashierScript := preload("res://scripts/cashier.gd")
const CustomerScript := preload("res://scripts/customer.gd")
const UnlockScript := preload("res://scripts/unlock_zone.gd")
const JoystickScript := preload("res://scripts/joystick.gd")
const StaffScript := preload("res://scripts/staff.gd")

const CAM_OFFSET := Vector3(12, 14, 12)
const ENTRANCE := Vector3(15, 0, 0)

var player: CharacterBody3D
var cam: Camera3D
var cashier: Node3D
var shelves: Array[Node3D] = []
var producers: Array[Node3D] = []
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
	_add_unlock("staff1", 150, Vector3(-3, 0, -6.5), func(): _hire_staff(Vector3(-3, 0, -6)))
	_add_unlock("staff2", 400, Vector3(0, 0, -6.5), func(): _hire_staff(Vector3(0, 0, -6)))
	_add_unlock("cashier", 200, Vector3(-3, 0, 0), func():
		cashier.set_auto(true))


func _add_producer(product: String, pos: Vector3, cap: int, every: float) -> Node3D:
	var p := ProducerScript.new()
	p.setup(product, cap, every)
	p.position = pos
	add_child(p)
	producers.append(p)
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


func _hire_staff(at: Vector3) -> void:
	var st := StaffScript.new()
	st.main = self
	st.position = at
	add_child(st)


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
	_build_upgrade_panel(layer)
	Game.money_changed.connect(func(v): _money_label.text = "$ %d" % v)
	_money_label.text = "$ %d" % Game.money


func _build_upgrade_panel(layer: CanvasLayer) -> void:
	var panel := PanelContainer.new()
	panel.visible = false
	panel.position = Vector2(140, 300)
	panel.custom_minimum_size = Vector2(800, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Upgrades"
	title.add_theme_font_size_override("font_size", 48)
	box.add_child(title)

	var buttons := {}
	for id in Game.UPGRADES:
		var b := Button.new()
		b.add_theme_font_size_override("font_size", 40)
		b.custom_minimum_size = Vector2(0, 110)
		b.pressed.connect(func(): Game.buy_upgrade(id))
		box.add_child(b)
		buttons[id] = b
	var refresh := func():
		for id in buttons:
			var b: Button = buttons[id]
			var name: String = Game.UPGRADES[id][0]
			if Game.is_maxed(id):
				b.text = "%s  Lv %d (MAX)" % [name, Game.level(id)]
				b.disabled = true
			else:
				b.text = "%s  Lv %d  -  $%d" % [name, Game.level(id), Game.upgrade_cost(id)]
				b.disabled = Game.money < Game.upgrade_cost(id)
	Game.money_changed.connect(func(_v): refresh.call())
	Game.upgrades_changed.connect(refresh)
	refresh.call()

	var close := Button.new()
	close.text = "Close"
	close.add_theme_font_size_override("font_size", 40)
	close.custom_minimum_size = Vector2(0, 100)
	close.pressed.connect(func(): panel.visible = false)
	box.add_child(close)

	var open := Button.new()
	open.text = "Upgrades"
	open.add_theme_font_size_override("font_size", 40)
	open.position = Vector2(740, 36)
	open.custom_minimum_size = Vector2(300, 100)
	open.pressed.connect(func():
		refresh.call()
		panel.visible = true)
	layer.add_child(open)
	layer.add_child(panel)
