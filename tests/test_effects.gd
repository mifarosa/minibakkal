extends SceneTree
## Smoke test: coins fly to the HUD and the unlock pad fills / disappears when paid.

var main: Node
var frames := 0
var elapsed := 0.0
var coins_seen := 0


func _initialize() -> void:
	# Start from a clean save so the corn pad exists and money is known.
	var f := FileAccess.open("user://save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"money": 1000, "unlocked": {}, "levels": {}}))
	f.close()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(delta: float) -> bool:
	frames += 1
	elapsed += delta
	if frames == 5:
		main.cashier._fly_coins(Vector3(0, 0, 0))
	if frames == 8:
		for c in main.get_children():
			if c is MeshInstance3D and c.scale.x > 1.4:
				coins_seen += 1
		assert(coins_seen == 3, "expected 3 flying coins, got %d" % coins_seen)
		# Pay for the cheapest pad directly
		var pad: Node = null
		for c in main.get_children():
			if c.has_method("setup") and c.get("id") == "corn":
				pad = c
		assert(pad != null)
		pad._player = main.player
	if frames > 8 and (root.get_node("Game").unlocked.has("corn") or elapsed > 20.0):
		var g = root.get_node("Game")
		assert(g.unlocked.has("corn"), "corn pad should be paid")
		assert(g.money < 1000)
		print("EFFECTS TESTS PASSED")
		quit()
	return false
