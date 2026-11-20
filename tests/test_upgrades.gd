extends SceneTree

func _initialize() -> void:
	var g = root.get_node("Game")
	g.levels = {}
	g.money = 0
	assert(not g.buy_upgrade("speed"))          # no money
	g.money = 1000
	assert(g.upgrade_cost("speed") == 100)
	assert(g.buy_upgrade("speed"))
	assert(g.money == 900 and g.level("speed") == 1)
	assert(g.upgrade_cost("speed") == 170)       # 100 * 1.7
	assert(is_equal_approx(g.player_speed(), 6.0 * 1.12))
	g.money = 99999
	for i in 10: g.buy_upgrade("capacity")
	assert(g.level("capacity") == 5 and g.is_maxed("capacity"))
	assert(g.carry_capacity() == 18)
	g.levels["income"] = 2
	assert(g.price_of("tomato") == 13)           # 10 * 1.3
	print("UPGRADE TESTS PASSED")
	quit()
