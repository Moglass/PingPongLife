extends Node
## 竖屏验收：按 393×852 真实手机尺寸截日常页与档案页三个 tab。

func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(393, 852))
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout

	var main: Control = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	GameManager.new_career("陈默", "prodigy")
	main._enter_game()
	for i in range(40):
		GameManager.p.ap = 3
		GameManager.train("tech", "fh")
		GameManager.advance_week()
	GameManager.p.record["matches"] = 24
	GameManager.p.record["wins"] = 17
	GameManager.p.record["champions"] = 2
	GameManager.p.record["prize"] = 86000
	GameManager.p.money = 12800
	GameManager.p.best_rank = 37

	await get_tree().process_frame
	print("[PORTRAIT] viewport=", get_viewport().get_visible_rect().size, " is_portrait=", UIKit.is_portrait())

	main.show_page(main.Page.CAREER)
	await _shot("p_career")

	main.show_page(main.Page.PROFILE)
	if main.current_view != null:
		main.current_view.tab = 0
		main.current_view.refresh()
	await _shot("p_profile")

	if main.current_view != null:
		main.current_view.tab = 1
		main.current_view.refresh()
	await _shot("p_gear")

	if main.current_view != null:
		main.current_view.tab = 2
		main.current_view.refresh()
	await _shot("p_achv")

	# 竖屏比赛页：先推进到有赛事的周
	main.show_page(main.Page.CAREER)
	await get_tree().process_frame
	var guard := 0
	while GameManager.available_tourneys().is_empty() and guard < 24:
		guard += 1
		GameManager.advance_week()
	var list: Array = GameManager.available_tourneys()
	print("[PORTRAIT] 可报名赛事 ", list.size(), " 周=", GameManager.p.week)
	if not list.is_empty():
		GameManager.enter_tournament(list[0], int(list[0].get("recommended", 0)))
		var ctx: Dictionary = GameManager.begin_round()
		print("[PORTRAIT] begin_round ok=", not ctx.is_empty())
		if not ctx.is_empty():
			await get_tree().create_timer(3.0).timeout
			await _shot("p_match_panel")

	get_tree().quit()

func _shot(name: String) -> void:
	await get_tree().create_timer(0.55).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("D:/workbuddys/table tennis/PingPongLife/shots/%s.png" % name)
	print("[SHOT] ", name)
