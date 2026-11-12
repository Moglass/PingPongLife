extends Node
## 生涯集成测试：godot --headless --path . tools/TestRunner.tscn

func _ready() -> void:
	print("=== v0.8 生涯集成测试 ===")
	var gm = get_node("/root/GameManager")
	var dm = get_node("/root/DataManager")
	var fm = get_node("/root/ForumManager")
	assert(gm != null, "GameManager 未加载")
	assert(dm != null, "DataManager 未加载")

	gm.new_career("陈默", "sports_family")
	print("[START] %d 岁 · %s · Ovr %.1f · 对手池 %d" % [
		gm.p.age, gm.stage_name(), gm.p.ovr(), gm.world.list.size()])

	var years := 0
	var matches := 0
	var titles := 0
	var guard := 0
	while gm.p.age < 26 and guard < 1200:
		guard += 1
		# 训练：用完 AP。技术 45% / 体能 25% / 心理 20% / 战术 10%
		var ap_guard := 0
		while gm.p.ap > 0 and ap_guard < 10:
			ap_guard += 1
			if gm.p.stamina_cur < 30.0:
				gm.train("rest")
				continue
			var roll: float = gm.event_pool.rng.randf()
			if roll < 0.45:
				var weakest := "fh"
				var wv := 999.0
				for k in PlayerStats.TECH_KEYS:
					if gm.p.get_tech(k) < wv:
						wv = gm.p.get_tech(k)
						weakest = k
				gm.train("tech", weakest)
			elif roll < 0.70:
				gm.train("fit")
			elif roll < 0.90:
				gm.train("psy")
			else:
				gm.train("tac")

		# 赛事：有就报，打完
		var list: Array = gm.available_tourneys()
		if not list.is_empty():
			list.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
				return int(x.get("stage", 0)) < int(y.get("stage", 0))
			)
			var t: Dictionary = list[0]
			var ch := int(t.get("recommended", 0))
			gm.enter_tournament(t, ch)
			var rguard := 0
			while gm.has_next_round() and rguard < 8:
				rguard += 1
				var ctx: Dictionary = gm.begin_round()
				if ctx.is_empty():
					break
				# 用引擎快进模拟（等同于跳过档）
				gm.engine.simulate_remaining(_pick_tactic(ctx), "steady")
				var won: bool = gm.engine.winner == 0
				var res: Dictionary = gm.conclude_match(won)
				matches += 1
				if int(res.get("place", 99)) == 1:
					titles += 1
			# 打完一站补体力
			gm.p.stamina_cur = minf(100.0, gm.p.stamina_cur + 12.0)

		gm.advance_week()
		if gm.p.week == 1:
			years += 1

	print("[END] %d 岁 · %s · Ovr %.1f · 排名 %d · 积分 %d · 资金 %d" % [
		gm.p.age, gm.stage_name(), gm.p.ovr(), gm.p.rank, gm.p.points, gm.p.money])
	print("[ATTR] 力%.1f 速%.1f 耐%.1f 手%.1f 战%.1f 心%.1f" % [gm.p.power, gm.p.speed, gm.p.stamina, gm.p.touch, gm.p.tactic, gm.p.mental])
	print("[TECH] 发%.1f 接%.1f 台%.1f 正%.1f 反%.1f 防%.1f 步%.1f" % [gm.p.tech_serve, gm.p.tech_receive, gm.p.tech_short, gm.p.tech_fh, gm.p.tech_bh, gm.p.tech_def, gm.p.tech_foot])
	print("[CAP] ladder=%.0f  stage=%d  ap=%d" % [gm.p.ladder_cap(), gm.p.stage, gm.p.ap_max])
	print("[STAT] 比赛 %d 场 · 冠军 %d · 胜率 %.0f%% · 论坛帖 %d" % [
		matches, titles,
		float(gm.p.record.get("wins", 0)) / maxf(1.0, float(gm.p.record.get("matches", 0))) * 100.0,
		fm.threads.size()])
	print("[WORLD] 对手 %d · 退役 %d" % [gm.world.active().size(), gm.world.list.size() - gm.world.active().size()])

	# 存档往返
	var ok: bool = gm.save_to(3)
	var ovr_before: float = gm.p.ovr()
	var pts_before: int = gm.p.points
	gm.load_from(3)
	print("[SAVE] 写入 %s · 读回 Ovr %.1f (原 %.1f) · 积分 %d (原 %d)" % [
		"OK" if ok else "FAIL", gm.p.ovr(), ovr_before, gm.p.points, pts_before])
	assert(absf(gm.p.ovr() - ovr_before) < 0.01, "存档往返后 Ovr 必须一致")
	assert(gm.p.points == pts_before, "存档往返后积分必须一致")

	# 压力与退役
	gm.p.age = 31
	gm.p.rank = 55
	var pres: Dictionary = gm.check_pressure()
	print("[PRESSURE] level=%d %s" % [int(pres.get("level", 0)), str(pres.get("notes", []))])
	gm.retire("veteran")
	print("[RETIRE] phase=%d" % int(gm.phase))

	print("=== 通过 ===")
	get_tree().quit()

func _pick_tactic(ctx: Dictionary) -> String:
	var opp: Dictionary = ctx.get("opponent", {})
	var weak: Array = opp.get("weakness", [])
	if weak.has("bh"):
		return "target_bh"
	if weak.has("fh"):
		return "rush_fh"
	if weak.has("mid"):
		return "target_mid"
	return "short_game"
