extends Node
## UI 冒烟：真实走一遍「下一周 / 切页 / 存档 / 读档」，抓运行时错误。

func _ready() -> void:
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	GameManager.new_career("陈默", "working_class")
	main._enter_game()
	await get_tree().process_frame

	for i in range(26):
		main._next_week()
		await get_tree().process_frame
	print("[SMOKE] 推进 26 周 OK · age=", GameManager.p.age, " week=", GameManager.p.week, " 事件=", not GameManager.pending_event.is_empty())

	for p in [main.Page.TOURNEY, main.Page.FORUM, main.Page.PROFILE, main.Page.CAREER]:
		main.show_page(p)
		await get_tree().process_frame
	print("[SMOKE] 四个页面切换 OK")

	var ok := GameManager.save_to(2)
	var ovr := GameManager.p.ovr()
	var loaded := GameManager.load_from(2)
	print("[SMOKE] 存档=", ok, " 读档=", loaded, " Ovr 一致=", absf(GameManager.p.ovr() - ovr) < 0.01)

	# 训一次 + 事件应用
	GameManager.p.ap = 3
	var r := GameManager.train("tech", "bh")
	print("[SMOKE] 训练：", r.get("text", "").substr(0, 20), " gains=", r.get("gains", []))

	# 开一站比赛并跳过
	var list: Array = GameManager.available_tourneys()
	print("[SMOKE] 可报名赛事：", list.size())
	if not list.is_empty():
		GameManager.enter_tournament(list[0], int(list[0].get("recommended", 0)))
		var ctx := GameManager.begin_round()
		if not ctx.is_empty():
			GameManager.engine.simulate_remaining("target_bh", "steady")
			var res := GameManager.conclude_match(GameManager.engine.winner == 0)
			print("[SMOKE] 比赛结算 OK · won=", res.get("won"), " place=", res.get("place"))
	print("[SMOKE] 全部通过")
	get_tree().quit()
