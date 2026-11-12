extends Node
## 自动截图：godot --path . tools/Shot.tscn
## 依次渲染标题 / 日常 / 赛事 / 比赛 / 复盘，用于视觉验收。

const OUT := "D:/workbuddys/table tennis/PingPongLife/shots/"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().create_timer(0.8).timeout
	await _shot("01_title.png")

	# 进入生涯
	GameManager.new_career("陈默", "prodigy")
	main._enter_game()
	await get_tree().create_timer(0.6).timeout
	await _shot("02_career.png")

	# 成长一些，让页面有内容
	for i in range(120):
		GameManager.p.ap = 3
		GameManager.train("tech", "fh")
		GameManager.train("fit")
		GameManager.train("psy")
		GameManager.advance_week()
	GameManager.p.age = 17
	GameManager.p.stage = 3
	GameManager.update_ranking()
	main._build_topbar()
	main.show_page(main.Page.CAREER)
	await get_tree().create_timer(0.6).timeout
	await _shot("03_career_mid.png")

	main.show_page(main.Page.TOURNEY)
	await get_tree().create_timer(0.5).timeout
	await _shot("04_tourney.png")

	main.show_page(main.Page.FORUM)
	await get_tree().create_timer(0.5).timeout
	await _shot("05_forum.png")

	main.show_page(main.Page.PROFILE)
	await get_tree().create_timer(0.5).timeout
	await _shot("06_profile.png")

	# 开一场比赛
	var list: Array = GameManager.available_tourneys()
	if not list.is_empty():
		var t: Dictionary = list[0]
		GameManager.enter_tournament(t, int(t.get("recommended", 0)))
		GameManager.begin_round()
		await get_tree().create_timer(2.4).timeout
		await _shot("07_match_tactic.png")
		# 点第一个「用这套」
		for b in main.find_children("*", "Button", true, false):
			if b is Button and (b as Button).text == "用这套":
				(b as Button).pressed.emit()
				break
		await get_tree().create_timer(2.2).timeout
		await _shot("08_match_live.png")
		await get_tree().create_timer(1.6).timeout
		await _shot("09_match_live2.png")
		# 造一个 9 平，触发关键分面板
		var mv = main.current_view
		if mv != null and mv.get("engine") != null:
			mv.engine.score[0] = 9
			mv.engine.score[1] = 9
			await get_tree().create_timer(1.2).timeout
			await _shot("11_critical.png")
			mv.critical_choice_made.emit("steady")
			await get_tree().create_timer(0.8).timeout
		# 跳过剩余，进复盘
		for b in main.find_children("*", "Button", true, false):
			if b is Button and (b as Button).text == "跳过":
				(b as Button).pressed.emit()
				break
		await get_tree().create_timer(2.0).timeout
		await _shot("10_review.png")

	# 事件卡
	GameManager.pending_event = {}
	var card: Dictionary = GameManager.event_pool.pick_for(GameManager.p, false)
	for i in range(6):
		if not card.is_empty():
			break
		card = GameManager.event_pool.pick_for(GameManager.p, false)
	if card.is_empty():
		card = {
			"title": "寄来的包裹", "kind": "家庭",
			"text": "你妈寄来了一箱土特产，还有一件她亲手织的毛衣，虽然现在穿有点热，而且款式有点土。",
			"options": [
				{"text": "试穿一下并发照片", "effect_text": "下一周获得【后盾】", "fx": {"status": {"id": "backing", "name": "后盾", "weeks": 2, "form": 0.05}}},
				{"text": "塞进柜子，继续训练", "effect_text": "无消耗", "fx": {"log": "你把毛衣塞进柜子，继续去练球。"}},
			],
		}
	main.show_page(main.Page.CAREER)
	await get_tree().create_timer(0.4).timeout
	main._show_event(card)
	await get_tree().create_timer(0.5).timeout
	await _shot("12_event.png")

	main._close_modal()
	await get_tree().create_timer(0.25).timeout

	# 器材
	main.show_page(main.Page.PROFILE)
	await get_tree().create_timer(0.3).timeout
	if main.current_view != null:
		main.current_view.tab = 1
		main.current_view.refresh()
	await get_tree().create_timer(0.5).timeout
	await _shot("13_gear.png")

	# 成就
	if main.current_view != null:
		main.current_view.tab = 2
		main.current_view.refresh()
	await get_tree().create_timer(0.5).timeout
	await _shot("14_achievements.png")

	# 团体赛排阵
	GameManager.phase = GameManager.Phase.CAREER
	var tev: Dictionary = TeamSystem.TEAM_EVENTS[3]
	GameManager.enter_team_event(tev)
	main.show_page(main.Page.TEAM)
	await get_tree().create_timer(0.6).timeout
	await _shot("15_team_board.png")

	# 模拟到结束
	GameManager.team_run["started"] = true
	var guard := 0
	while not bool(GameManager.team_run.get("done", false)) and guard < 10:
		guard += 1
		if GameManager.team.is_player_turn(GameManager.team_run):
			var st := GameManager.team_step()
			if str(st.get("kind", "")) == "player":
				GameManager.engine.simulate_remaining("target_bh", "steady")
				GameManager.conclude_match(GameManager.engine.winner == 0)
		else:
			GameManager.team_step()
	if main.current_view != null and main.current_view.has_method("refresh"):
		main.current_view.refresh()
	await get_tree().create_timer(0.6).timeout
	await _shot("16_team_result.png")

	get_tree().quit()

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := OUT + name
	var err := img.save_png(path)
	print("[SHOT] %s -> %s (%dx%d)" % [name, "ok" if err == OK else str(err), img.get_width(), img.get_height()])
